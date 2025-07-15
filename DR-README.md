# LAMP Stack Disaster Recovery on AWS ECS

This repository implements a comprehensive disaster recovery (DR) solution for a containerized LAMP (Linux, Apache, MySQL, PHP) application using AWS ECS Fargate with cross-region replication between `eu-west-1` (primary) and `us-east-1` (DR).

## 🏗️ Architecture Overview

### Primary Region (eu-west-1)
- **ECS Cluster**: Running LAMP application containers
- **RDS MySQL**: Primary database instance
- **ALB**: Application Load Balancer
- **S3**: Primary bucket for static assets

### DR Region (us-east-1)
- **ECS Cluster**: Pilot light configuration (0 desired tasks)
- **RDS Read Replica**: Cross-region read replica of primary DB
- **ALB**: Pre-configured load balancer (ready for activation)
- **S3**: Cross-region replicated bucket
- **VPC**: Complete network infrastructure mirror

## 🟢 Current DR Infrastructure Status

✅ **DR Infrastructure Successfully Deployed and Active**

- **Primary Database**: `test-db` (eu-west-1)
- **DR Read Replica**: `lamp-app-dr-read-replica` (us-east-1)
- **DR Application URL**: http://lamp-app-dr-alb-1284648996.us-east-1.elb.amazonaws.com/
- **ECS Service**: 2 tasks running and healthy
- **Database Replication**: Active cross-region read replica
- **Last Verified**: July 15, 2025

### Quick Verification
```bash
# Test DR endpoint
curl http://lamp-app-dr-alb-1284648996.us-east-1.elb.amazonaws.com/index.php
# Expected: ✅ Hello from PHP Docker + ECS + RDS!
```

## 📁 Repository Structure

```
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Provider configuration and variables
│   ├── networking.tf       # VPC, subnets, and networking
│   ├── security.tf         # Security groups
│   ├── load_balancer.tf    # Application Load Balancer
│   ├── rds.tf              # RDS read replica configuration
│   ├── ecs.tf              # ECS cluster and services
│   ├── iam.tf              # IAM roles and policies
│   ├── s3.tf               # S3 cross-region replication
│   ├── route53.tf          # DNS failover (optional)
│   ├── monitoring.tf       # CloudWatch alarms and SNS
│   └── outputs.tf          # Resource outputs
├── task-definitions/       # ECS task definitions
│   ├── lamp-task-def.json  # Original production task
│   └── task-dr.json        # DR task definition
├── scripts/                # DR automation scripts
│   ├── activate-dr.sh      # Disaster recovery activation
│   ├── test-dr.sh          # DR testing without impact
│   ├── recover-primary.sh  # Recovery back to primary
│   └── monitor-dr.sh       # DR environment monitoring
├── Dockerfile              # Container definition
├── index.php               # Sample PHP application
└── docker-compose.yml      # Local development (optional)
```

## 🚀 Deployment Instructions

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **Docker** for building container images
4. **Valid AWS credentials** for both regions

### Step 1: Deploy Infrastructure

1. **Clone and navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review and modify variables** in `main.tf`:
   ```hcl
   variable "app_name" {
     default = "lamp-app"  # Customize as needed
   }
   
   variable "db_password" {
     default = "YourSecurePassword"  # Use a secure password
   }
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure:**
   ```bash
   terraform apply
   ```

   This will create:
   - Complete VPC infrastructure in us-east-1
   - RDS read replica from your existing primary database
   - ECS cluster with 0 desired tasks (pilot light)
   - Application Load Balancer
   - S3 cross-region replication
   - CloudWatch monitoring and alarms

### Step 2: Container Image Setup

1. **Push your container image to ECR in both regions:**
   ```bash
   # Tag for DR region
   docker tag lamp-app:latest 149536452878.dkr.ecr.us-east-1.amazonaws.com/lamp-app:latest
   
   # Push to DR region ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 149536452878.dkr.ecr.us-east-1.amazonaws.com
   docker push 149536452878.dkr.ecr.us-east-1.amazonaws.com/lamp-app:latest
   ```

### Step 3: Configure Monitoring

1. **Update SNS topic subscription** in `terraform/monitoring.tf`:
   ```hcl
   resource "aws_sns_topic_subscription" "dr_email_alerts" {
     topic_arn = aws_sns_topic.dr_alerts.arn
     protocol  = "email"
     endpoint  = "your-email@example.com"  # Replace with your email
   }
   ```

2. **Apply the monitoring configuration:**
   ```bash
   terraform apply -target=aws_sns_topic_subscription.dr_email_alerts
   ```

## 🧪 Testing the DR Setup

### Test DR Environment Health
```bash
./scripts/monitor-dr.sh
```

### Perform DR Activation Test
```bash
./scripts/test-dr.sh
```

This script will:
- Scale ECS service to 1 task temporarily
- Test application connectivity
- Scale back to 0 to save costs
- Report on readiness

## 🚨 Disaster Recovery Procedures

### 1. Activate Disaster Recovery

When a disaster occurs in the primary region:

```bash
./scripts/activate-dr.sh
```

This script will:
1. **Promote RDS read replica** to standalone primary
2. **Update database endpoint** in SSM Parameter Store
3. **Scale ECS service** from 0 to 2 tasks
4. **Provide new application endpoint**

**Expected Output:**
```
🎉 Disaster Recovery Activation Complete!
================================================
✅ RDS Read Replica promoted to primary
✅ ECS Service scaled to 2 tasks
✅ Application available at: http://lamp-app-dr-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com
```

### 2. DNS Failover (Manual)

Update your DNS records to point to the DR region:
- **ALB Endpoint**: Use output from activation script
- **Route 53**: Update A records or use health check failover
- **TTL**: Ensure low TTL for faster propagation

### 3. Monitor DR Operations

```bash
./scripts/monitor-dr.sh
```

Continuously monitor:
- ECS task health
- Database performance
- Application response times
- CloudWatch metrics

## 🔄 Recovery Back to Primary Region

When the primary region is restored:

```bash
./scripts/recover-primary.sh
```

**Manual steps required:**
1. **Database synchronization**: Set up replication from DR back to primary
2. **DNS cutover**: Update DNS to point back to primary region
3. **Traffic verification**: Ensure primary region handles traffic correctly
4. **DR reset**: Re-establish read replica for future DR needs

## 📊 Monitoring and Alerting

### CloudWatch Alarms

- **RDS Replica Lag**: Monitors replication delay (threshold: 60 seconds)
- **ECS CPU Utilization**: Monitors container performance (threshold: 80%)
- **ALB Target Health**: Monitors application availability

### Key Metrics to Monitor

1. **RDS Metrics:**
   - Replica lag
   - Connection count
   - CPU and memory utilization

2. **ECS Metrics:**
   - Task health
   - CPU and memory utilization
   - Task count vs desired count

3. **ALB Metrics:**
   - Target health
   - Response times
   - Error rates

## 💰 Cost Optimization

### Pilot Light Strategy
- **ECS Service**: 0 desired tasks when not in use
- **RDS**: Read replica uses smaller instance class (t3.micro)
- **S3**: Lifecycle policies move old versions to Glacier
- **Cross-region traffic**: Minimized through efficient replication

### Cost Estimates (Monthly)
- **RDS Read Replica**: ~$15 (t3.micro)
- **S3 Cross-region replication**: ~$10 (per TB)
- **VPC NAT Gateway**: ~$45
- **CloudWatch**: ~$5
- **Total**: ~$75/month for DR readiness

## 🔧 Troubleshooting

### Common Issues

1. **RDS Promotion Fails:**
   ```bash
   aws rds describe-db-instances --db-instance-identifier lamp-app-dr-read-replica --region us-east-1
   ```

2. **ECS Tasks Not Starting:**
   ```bash
   aws ecs describe-services --cluster lamp-app-dr-cluster --services lamp-app-dr-service --region us-east-1
   aws logs tail /ecs/lamp-app-dr-task --region us-east-1
   ```

3. **Application Not Responding:**
   ```bash
   aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-east-1
   ```

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster lamp-app-dr-cluster --services lamp-app-dr-service --region us-east-1

# Check RDS replica status
aws rds describe-db-instances --db-instance-identifier lamp-app-dr-read-replica --region us-east-1

# View application logs
aws logs tail /ecs/lamp-app-dr-task --region us-east-1 --follow

# Check S3 replication metrics
aws s3api get-bucket-replication --bucket lamp-app-assets-primary-<suffix> --region eu-west-1
```

## 🔒 Security Considerations

1. **IAM Roles**: Least privilege access for ECS tasks
2. **Security Groups**: Restricted access between components
3. **SSL/TLS**: Implement HTTPS in production
4. **Secrets Management**: Database passwords stored in SSM Parameter Store
5. **VPC**: Private subnets for application and database tiers

## 📈 Next Steps for Production

1. **SSL Certificate**: Add ACM certificate to ALB
2. **Custom Domain**: Configure Route 53 with health checks
3. **Enhanced Monitoring**: Add custom metrics and dashboards
4. **Backup Strategy**: Implement automated RDS snapshots
5. **Security Hardening**: Enable VPC Flow Logs, GuardDuty
6. **Compliance**: Implement logging and audit trails

## 🎯 Testing Checklist

- [ ] Terraform deployment successful
- [ ] RDS read replica healthy with low lag
- [ ] ECS cluster and service created
- [ ] S3 cross-region replication working
- [ ] DR test script passes
- [ ] CloudWatch alarms configured
- [ ] SNS notifications working
- [ ] Application accessible during DR test

## 📞 Support

For issues or questions:
1. Check CloudWatch logs for detailed error messages
2. Use monitoring script for health status
3. Review Terraform state for infrastructure issues
4. Monitor AWS Service Health Dashboard for regional issues

---

**Original Production URL**: http://54.171.123.30/
**DR Region**: us-east-1
**Primary Region**: eu-west-1
