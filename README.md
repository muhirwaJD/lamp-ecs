# LAMP Stack Hosted on AWS ECS (Fargate)

This repository contains the necessary files and instructions to deploy a containerized PHP-based LAMP (Linux, Apache, MySQL, PHP) application using AWS ECS Fargate, connecting to an Amazon RDS MySQL database.

## Repository Structure

```
.
├── Dockerfile
├── index.php
├── task-definition.json
└── start.sh
```

## Application Components

* **Apache Web Server:** Hosts the PHP application.
* **PHP 8.2:** Executes server-side PHP scripts.
* **MySQL:** Managed through AWS RDS.

## Setup and Deployment Steps

### 1. Docker Image Preparation

Build and push your Docker image to Amazon ECR:

```bash
docker build -t lamp-app .
docker tag lamp-app:latest <your-ecr-repository-url>
docker push <your-ecr-repository-url>
```

### 2. ECS Task Definition

* Use `task-definition.json` to create an ECS task definition.

### 3. Deploy ECS Service

* Create an ECS service using Fargate as the launch type.
* Select the previously created task definition.

### 4. Database Connection

* Update environment variables in `task-definition.json` to connect to your RDS instance.

### 5. Access the Application

After successful deployment, access your application through the provided ECS IP:

```
http://54.171.123.30/
```

## Maintenance

* Regularly update and rebuild your Docker image for security patches.
* Monitor application logs via AWS CloudWatch.

## Security

* Securely manage sensitive information using environment variables and AWS IAM roles.

## Notes

* Ensure proper AWS security groups configuration to allow communication between ECS and RDS.
