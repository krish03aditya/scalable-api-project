terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# DATA SOURCES
############################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# SECURITY GROUP
############################

resource "aws_security_group" "web_sg" {
  name = var.sg_name
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# IAM ROLE FOR ECR
############################

resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_role.name
}

############################
# KEY PAIR
############################

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = file("terraform-key.pub")
}

############################
# LAUNCH TEMPLATE
############################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "fastapi-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y docker awscli
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin 585837523973.dkr.ecr.${var.aws_region}.amazonaws.com

docker pull 585837523973.dkr.ecr.${var.aws_region}.amazonaws.com/fastapi-app:latest

docker run -d -p 8000:8000 585837523973.dkr.ecr.${var.aws_region}.amazonaws.com/fastapi-app:latest
EOF
)
}

############################
# TARGET GROUP
############################

resource "aws_lb_target_group" "app_tg" {
  name     = "fastapi-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path    = "/health"
    matcher = "200"
  }
}

############################
# APPLICATION LOAD BALANCER
############################

resource "aws_lb" "app_alb" {
  name               = "fastapi-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.web_sg.id]
}

############################
# LISTENER
############################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

############################
# AUTO SCALING GROUP
############################

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]
}

############################
# AUTO SCALING POLICY
############################

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}