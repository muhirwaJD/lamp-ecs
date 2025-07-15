#!/bin/bash

# Disaster Recovery Activation Script
# This script activates the disaster recovery environment in us-east-1

set -e

# Configuration
DR_REGION="us-east-1"
PRIMARY_REGION="eu-west-1"
CLUSTER_NAME="lamp-app-dr-cluster"
SERVICE_NAME="lamp-app-dr-service"
DB_IDENTIFIER="lamp-app-dr-read-replica"

echo "🚨 Starting Disaster Recovery Activation..."

# Step 1: Promote RDS Read Replica
echo "📊 Step 1: Promoting RDS Read Replica to standalone database..."
aws rds promote-read-replica \
    --db-instance-identifier $DB_IDENTIFIER \
    --region $DR_REGION

echo "⏳ Waiting for RDS promotion to complete..."
aws rds wait db-instance-available \
    --db-instance-identifier $DB_IDENTIFIER \
    --region $DR_REGION

# Get the new RDS endpoint
NEW_DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --region $DR_REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "✅ RDS promoted successfully. New endpoint: $NEW_DB_ENDPOINT"

# Step 2: Update SSM Parameter with new DB endpoint
echo "📝 Step 2: Updating database endpoint in SSM Parameter Store..."
aws ssm put-parameter \
    --name "/lamp-app/dr/db/host" \
    --value "$NEW_DB_ENDPOINT" \
    --type "String" \
    --overwrite \
    --region $DR_REGION

echo "✅ SSM Parameter updated successfully"

# Step 3: Scale ECS Service
echo "🚀 Step 3: Scaling ECS service from 0 to 2 tasks..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 2 \
    --region $DR_REGION

echo "⏳ Waiting for ECS service to become stable..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $DR_REGION

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names "lamp-app-dr-alb" \
    --region $DR_REGION \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo ""
echo "🎉 Disaster Recovery Activation Complete!"
echo "================================================"
echo "✅ RDS Read Replica promoted to primary"
echo "✅ ECS Service scaled to 2 tasks"
echo "✅ Application available at: http://$ALB_DNS"
echo ""
echo "🔍 Verification steps:"
echo "1. Check application health: curl http://$ALB_DNS/index.php"
echo "2. Monitor ECS tasks: aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $DR_REGION"
echo "3. Monitor RDS: aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --region $DR_REGION"
echo ""
echo "⚠️  Next steps:"
echo "1. Update DNS records to point to DR region"
echo "2. Monitor application performance"
echo "3. Plan for recovery back to primary region"
