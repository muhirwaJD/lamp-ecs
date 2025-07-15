# LAMP ECS Disaster Recovery Infrastructure
# Primary Region: eu-west-1, DR Region: us-east-1

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure multiple providers for cross-region setup
provider "aws" {
  alias  = "primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-east-1"
}

# Data sources for existing resources in primary region
data "aws_caller_identity" "current" {}

# Variables
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "lamp-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "Muhirwa.!"
}

variable "container_image" {
  description = "Container image URI"
  type        = string
  default     = "149536452878.dkr.ecr.eu-west-1.amazonaws.com/lamp-app:latest"
}

variable "notification_email" {
  description = "Email address for DR notifications"
  type        = string
  default     = "admin@example.com"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dr_vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dr_rds_instance_class" {
  description = "RDS instance class for DR region"
  type        = string
  default     = "db.t3.micro"
}

variable "dr_ecs_desired_count" {
  description = "Initial desired count for DR ECS service (pilot light)"
  type        = number
  default     = 0
}
