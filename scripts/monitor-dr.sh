#!/bin/bash

# DR Environment Monitoring Script
# This script checks the health of DR components

set -e

# Configuration
DR_REGION="us-east-1"
PRIMARY_REGION="eu-west-1"
CLUSTER_NAME="lamp-app-dr-cluster"
SERVICE_NAME="lamp-app-dr-service"
DB_IDENTIFIER="lamp-app-dr-read-replica"
ALB_NAME="lamp-app-dr-alb"

echo "📊 DR Environment Health Check"
echo "=============================="
echo "Primary Region: $PRIMARY_REGION"
echo "DR Region: $DR_REGION"
echo ""

# Check RDS Read Replica
echo "🗄️  RDS Read Replica Status:"
RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --region $DR_REGION \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$RDS_STATUS" = "available" ]; then
    echo "   ✅ Status: $RDS_STATUS"
    
    # Check replication lag
    REPLICA_LAG=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/RDS \
        --metric-name ReplicaLag \
        --dimensions Name=DBInstanceIdentifier,Value=$DB_IDENTIFIER \
        --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 300 \
        --statistics Average \
        --region $DR_REGION \
        --query 'Datapoints[-1].Average' \
        --output text 2>/dev/null || echo "N/A")
    
    echo "   📈 Replication Lag: ${REPLICA_LAG} seconds"
else
    echo "   ❌ Status: $RDS_STATUS"
fi

# Check ECS Cluster
echo ""
echo "🐳 ECS Cluster Status:"
CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters $CLUSTER_NAME \
    --region $DR_REGION \
    --query 'clusters[0].status' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    echo "   ✅ Cluster: $CLUSTER_STATUS"
    
    # Check running tasks
    RUNNING_TASKS=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $DR_REGION \
        --query 'services[0].runningCount' \
        --output text 2>/dev/null || echo "0")
    
    DESIRED_TASKS=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $DR_REGION \
        --query 'services[0].desiredCount' \
        --output text 2>/dev/null || echo "0")
    
    echo "   📊 Tasks: $RUNNING_TASKS/$DESIRED_TASKS running"
else
    echo "   ❌ Cluster: $CLUSTER_STATUS"
fi

# Check Load Balancer
echo ""
echo "⚖️  Load Balancer Status:"
ALB_STATE=$(aws elbv2 describe-load-balancers \
    --names $ALB_NAME \
    --region $DR_REGION \
    --query 'LoadBalancers[0].State.Code' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$ALB_STATE" = "active" ]; then
    echo "   ✅ ALB: $ALB_STATE"
    
    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --names $ALB_NAME \
        --region $DR_REGION \
        --query 'LoadBalancers[0].DNSName' \
        --output text)
    
    echo "   🌐 Endpoint: http://$ALB_DNS"
    
    # Check target group health
    TG_ARN=$(aws elbv2 describe-target-groups \
        --names "lamp-app-dr-tg" \
        --region $DR_REGION \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text 2>/dev/null || echo "")
    
    if [ "$TG_ARN" != "" ]; then
        HEALTHY_TARGETS=$(aws elbv2 describe-target-health \
            --target-group-arn $TG_ARN \
            --region $DR_REGION \
            --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
            --output text 2>/dev/null || echo "0")
        
        echo "   💚 Healthy Targets: $HEALTHY_TARGETS"
    fi
else
    echo "   ❌ ALB: $ALB_STATE"
fi

# Check S3 Replication
echo ""
echo "🪣 S3 Cross-Region Replication:"
PRIMARY_BUCKET=$(aws s3api list-buckets \
    --region $PRIMARY_REGION \
    --query 'Buckets[?contains(Name, `lamp-app-assets-primary`)].Name' \
    --output text 2>/dev/null || echo "")

DR_BUCKET=$(aws s3api list-buckets \
    --region $DR_REGION \
    --query 'Buckets[?contains(Name, `lamp-app-assets-dr`)].Name' \
    --output text 2>/dev/null || echo "")

if [ "$PRIMARY_BUCKET" != "" ] && [ "$DR_BUCKET" != "" ]; then
    echo "   ✅ Primary Bucket: $PRIMARY_BUCKET"
    echo "   ✅ DR Bucket: $DR_BUCKET"
    
    # Check replication status
    REPL_STATUS=$(aws s3api get-bucket-replication \
        --bucket $PRIMARY_BUCKET \
        --region $PRIMARY_REGION \
        --query 'ReplicationConfiguration.Rules[0].Status' \
        --output text 2>/dev/null || echo "NOT_CONFIGURED")
    
    echo "   🔄 Replication: $REPL_STATUS"
else
    echo "   ❌ S3 buckets not found or not accessible"
fi

# Summary
echo ""
echo "📋 Summary:"
echo "==========="

if [ "$RDS_STATUS" = "available" ] && [ "$CLUSTER_STATUS" = "ACTIVE" ] && [ "$ALB_STATE" = "active" ]; then
    echo "✅ DR Environment is HEALTHY and ready for activation"
else
    echo "❌ DR Environment has ISSUES that need attention"
fi

echo ""
echo "🔧 Useful Commands:"
echo "   Test DR: ./scripts/test-dr.sh"
echo "   Activate DR: ./scripts/activate-dr.sh"
echo "   Monitor logs: aws logs tail /ecs/lamp-app-dr-task --region $DR_REGION"
