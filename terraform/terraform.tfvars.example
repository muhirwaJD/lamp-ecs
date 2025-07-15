# terraform.tfvars.example
# Copy this file to terraform.tfvars and update with your values

# Application Configuration
app_name    = "lamp-app"
environment = "production"

# Container Configuration
container_image = "149536452878.dkr.ecr.eu-west-1.amazonaws.com/lamp-app:latest"

# Database Configuration
db_password = "Muhirwa.!"  # Change this to a secure password

# Notification Configuration
notification_email = "your-email@example.com"

# Regional Configuration
primary_region = "eu-west-1"
dr_region      = "us-east-1"

# Network Configuration
dr_vpc_cidr = "10.1.0.0/16"

# Cost Optimization
dr_rds_instance_class = "db.t3.micro"  # Use larger instance for production
dr_ecs_desired_count  = 0              # Pilot light - keep at 0
