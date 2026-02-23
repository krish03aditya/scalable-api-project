# 🚀 Scalable FastAPI Deployment on AWS

## 📌 Overview

This project demonstrates a production-style deployment of a FastAPI application on AWS using:

- Docker
- Amazon ECR
- EC2 Launch Templates
- Auto Scaling Groups
- Application Load Balancer
- Terraform (Infrastructure as Code)
- GitHub Actions (CI/CD)

The system automatically scales based on CPU utilization and is fully reproducible using Terraform.

---

## 🏗 Architecture

User  
⬇  
Application Load Balancer (ALB)  
⬇  
Target Group  
⬇  
Auto Scaling Group (ASG)  
⬇  
EC2 Instances (Docker running FastAPI)  
⬇  
Amazon ECR (Docker Image Registry) 

---

## ⚙️ Tech Stack

| Layer            | Technology                | 
|------------------|---------------------------|
| API              | FastAPI                   |    
| Containerization | Docker                    |
| Registry         | Amazon ECR                |
| Infrastructure   | Terraform                 |
| Compute          | EC2                       |
| Scaling          | Auto Scaling Group        |
| Load Balancing   | Application Load Balancer |
| CI/CD            | GitHub Actions            |

---

## 📁 Project Structure

scale-api-project/
│
├── application/
│   ├── app/
│   │   └── api.py
│   └── requirements.txt
│
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── Dockerfile
├── .dockerignore
├── .gitignore
└── README.md

---

## 🐳 Running Locally

Create virtual environment:
  python3 -m venv venv
  source venv/bin/activate
  pip install -r application/requirements.txt

Run application:
  uvicorn application.app.api:app –reload
  
Access at:
  http://127.0.0.1:8000

---

## 🐳 Docker Build

Build Docker image:
  docker build -t fastapi-app .
  
Run container:
  docker run -p 8000:8000 fastapi-app

---

## ☁️ Infrastructure Deployment (Terraform)

Initialize Terraform:
  cd infra
  terraform init

Apply configuration:
  terraform apply
        OR
  terraform apply -var=“account_id=YOUR_AWS_ACCOUNT_ID”

Destroy infrastructure:
  terraform destroy

  ---

## 🔁 CI/CD Pipeline

GitHub Actions workflow automatically:

1. Builds Docker image
2. Tags image with commit SHA
3. Pushes image to Amazon ECR

Triggered on push to `main` branch.

---

## 📈 Auto Scaling

- Minimum instances: 1
- Desired capacity: 2
- Maximum instances: 3
- Scaling policy: Target tracking
- Metric: ASGAverageCPUUtilization
- Target CPU: 60%

---

## 🧪 Load Testing

Simulate CPU surge inside EC2:
  yes > /dev/null &

Stop CPU surge:
  pkill yes

---

## 🔐 Security

- IAM Role attached to EC2 for ECR access
- No hardcoded credentials in code
- GitHub Secrets used for AWS authentication
- Infrastructure defined via Terraform

---

## 📦 Features

- Infrastructure as Code
- Immutable Docker deployments
- Load-balanced architecture
- Automatic horizontal scaling
- CI/CD enabled
- Production-style AWS setup

---

## 🧠 Learning Outcomes

This project demonstrates:

- End-to-end cloud deployment
- Infrastructure automation
- Dockerized microservices deployment
- CI/CD pipeline integration
- Auto Scaling implementation
- AWS networking fundamentals

---

## 📬 Author

Aditya Krish  
Cloud & DevOps Enthusiast











  
