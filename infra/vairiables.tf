variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "sg_name" {
  default = "fastapi-sg"
}

variable "allowed_cidr" {
  default = ["0.0.0.0/0"]
}