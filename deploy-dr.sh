#!/bin/bash

# LAMP Stack Disaster Recovery Deployment Script
# This script automates the deployment of the DR infrastructure

set -e

echo "🚀 LAMP Stack Disaster Recovery Deployment"
echo "=========================================="
echo ""

# Configuration
TERRAFORM_DIR="terraform"
SCRIPTS_DIR="scripts"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp "$TERRAFORM_DIR/terraform.tfvars.example" "$TERRAFORM_DIR/terraform.tfvars"
    echo "⚠️  Please edit terraform/terraform.tfvars with your specific values before proceeding."
    echo "   Especially update:"
    echo "   - notification_email"
    echo "   - db_password"
    echo ""
    read -p "Press Enter after updating terraform.tfvars to continue..."
fi

# Navigate to terraform directory
cd "$TERRAFORM_DIR"

echo "🏗️  Initializing Terraform..."
terraform init

echo ""
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

echo ""
echo "🚨 Review the plan above. This will create resources in AWS that may incur costs."
echo "💰 Estimated monthly cost: ~$75 for DR readiness"
echo ""
read -p "Do you want to proceed with the deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
echo ""
echo "📊 Deployment completed! Getting resource information..."
DR_ALB_DNS=$(terraform output -raw dr_alb_dns_name)
DR_RDS_ENDPOINT=$(terraform output -raw dr_rds_endpoint)
DR_CLUSTER=$(terraform output -raw dr_ecs_cluster_name)
DR_SERVICE=$(terraform output -raw dr_ecs_service_name)

echo ""
echo "🎉 Disaster Recovery Infrastructure Deployed Successfully!"
echo "========================================================"
echo ""
echo "📍 DR Region: us-east-1"
echo "🌐 DR ALB DNS: $DR_ALB_DNS"
echo "🗄️  DR RDS Endpoint: $DR_RDS_ENDPOINT"
echo "🐳 DR ECS Cluster: $DR_CLUSTER"
echo "⚙️  DR ECS Service: $DR_SERVICE"
echo ""
echo "📋 Next Steps:"
echo "1. Test the DR setup: ../scripts/test-dr.sh"
echo "2. Monitor DR health: ../scripts/monitor-dr.sh"
echo "3. Review CloudWatch alarms in AWS Console"
echo "4. Confirm SNS email subscription"
echo ""
echo "🆘 In case of disaster, activate DR with: ../scripts/activate-dr.sh"
echo ""
echo "📚 For detailed documentation, see:"
echo "   - DR-README.md (comprehensive guide)"
echo "   - ARCHITECTURE.md (architecture diagram)"
echo ""

# Navigate back to root
cd ..

# Make sure scripts are executable
chmod +x scripts/*.sh

echo "✅ All scripts are now executable"
echo ""
echo "🧪 Would you like to run a DR test now? (recommended)"
read -p "Run DR test? (yes/no): " test_confirm

if [ "$test_confirm" = "yes" ]; then
    echo ""
    echo "🧪 Running DR test..."
    ./scripts/test-dr.sh
fi

echo ""
echo "🎯 Deployment Complete! Your LAMP application now has disaster recovery capabilities."
