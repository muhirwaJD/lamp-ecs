#!/bin/bash

# Recovery Back to Primary Script
# This script recovers operations back to the primary region

set -e

# Configuration
DR_REGION="us-east-1"
PRIMARY_REGION="eu-west-1"
DR_CLUSTER_NAME="lamp-app-dr-cluster"
DR_SERVICE_NAME="lamp-app-dr-service"
PRIMARY_CLUSTER_NAME="lamp-cluster"  # Update with your primary cluster name
PRIMARY_SERVICE_NAME="lamp-service"  # Update with your primary service name

echo "🔄 Starting Recovery to Primary Region..."

# Step 1: Ensure primary region is healthy
echo "🏥 Step 1: Checking primary region health..."
# Add health checks for primary region here

# Step 2: Create new read replica from DR (now primary) back to original primary region
echo "📊 Step 2: Setting up reverse replication..."
echo "⚠️  This step requires manual intervention to set up new replication"
echo "   1. Take snapshot of current DR database"
echo "   2. Restore snapshot in primary region"
echo "   3. Set up replication from DR to primary"

# Step 3: Scale down DR services gradually
echo "📉 Step 3: Gradually scaling down DR services..."
aws ecs update-service \
    --cluster $DR_CLUSTER_NAME \
    --service $DR_SERVICE_NAME \
    --desired-count 1 \
    --region $DR_REGION

echo "⏳ Waiting 2 minutes before next scale down..."
sleep 120

# Step 4: Scale up primary region
echo "📈 Step 4: Scaling up primary region services..."
# Uncomment and modify these lines for your primary region
# aws ecs update-service \
#     --cluster $PRIMARY_CLUSTER_NAME \
#     --service $PRIMARY_SERVICE_NAME \
#     --desired-count 2 \
#     --region $PRIMARY_REGION

echo "⚠️  Manual DNS cutover required:"
echo "   1. Update Route 53 records to point back to primary region"
echo "   2. Monitor traffic shift"
echo "   3. Verify application health in primary region"

# Step 5: Final scale down of DR
echo "💰 Step 5: Final scale down of DR services..."
read -p "Press enter after confirming primary region is handling traffic..."

aws ecs update-service \
    --cluster $DR_CLUSTER_NAME \
    --service $DR_SERVICE_NAME \
    --desired-count 0 \
    --region $DR_REGION

echo ""
echo "🎉 Recovery Process Initiated!"
echo "============================="
echo "✅ DR services scaled down"
echo "⚠️  Manual steps remaining:"
echo "   1. Complete DNS cutover"
echo "   2. Monitor primary region"
echo "   3. Set up new DR read replica"
echo "   4. Update monitoring and alerts"
