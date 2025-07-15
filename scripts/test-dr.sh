#!/bin/bash

# Disaster Recovery Testing Script
# This script performs a failover test without affecting production

set -e

# Configuration
DR_REGION="us-east-1"
CLUSTER_NAME="lamp-app-dr-cluster"
SERVICE_NAME="lamp-app-dr-service"
DB_IDENTIFIER="lamp-app-dr-read-replica"

echo "🧪 Starting Disaster Recovery Test..."

# Step 1: Check RDS Read Replica Health
echo "📊 Step 1: Checking RDS Read Replica health..."
REPLICA_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --region $DR_REGION \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)

if [ "$REPLICA_STATUS" != "available" ]; then
    echo "❌ RDS Read Replica is not available. Status: $REPLICA_STATUS"
    exit 1
fi

REPLICA_LAG=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReplicaLag \
    --dimensions Name=DBInstanceIdentifier,Value=$DB_IDENTIFIER \
    --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region $DR_REGION \
    --query 'Datapoints[0].Average' \
    --output text)

echo "✅ RDS Read Replica Status: $REPLICA_STATUS"
echo "📈 Replication Lag: ${REPLICA_LAG:-N/A} seconds"

# Step 2: Test ECS Service Scaling
echo "🚀 Step 2: Testing ECS service scaling (1 task for test)..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 1 \
    --region $DR_REGION

echo "⏳ Waiting for ECS service to scale..."
sleep 30

# Check service status
RUNNING_COUNT=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $DR_REGION \
    --query 'services[0].runningCount' \
    --output text)

echo "📊 ECS Service Running Tasks: $RUNNING_COUNT"

# Step 3: Test Application Health
echo "🔍 Step 3: Testing application health..."
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names "lamp-app-dr-alb" \
    --region $DR_REGION \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo "🌐 Testing application at: http://$ALB_DNS"

# Wait for tasks to be healthy
echo "⏳ Waiting for tasks to become healthy..."
sleep 60

# Test application endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/index.php" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Application is responding correctly (HTTP $HTTP_STATUS)"
    RESPONSE=$(curl -s "http://$ALB_DNS/index.php")
    echo "📄 Response: $RESPONSE"
else
    echo "❌ Application test failed (HTTP $HTTP_STATUS)"
fi

# Step 4: Scale back down to save costs
echo "💰 Step 4: Scaling ECS service back to 0 to save costs..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 0 \
    --region $DR_REGION

echo ""
echo "🎯 Disaster Recovery Test Results:"
echo "=================================="
echo "RDS Replica Status: $REPLICA_STATUS"
echo "Replication Lag: ${REPLICA_LAG:-N/A} seconds"
echo "ECS Tasks Started: $RUNNING_COUNT"
echo "Application HTTP Status: $HTTP_STATUS"
echo "ALB Endpoint: http://$ALB_DNS"
echo ""

if [ "$REPLICA_STATUS" = "available" ] && [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ DR Test PASSED - System is ready for failover"
else
    echo "❌ DR Test FAILED - Issues need to be resolved"
    exit 1
fi
