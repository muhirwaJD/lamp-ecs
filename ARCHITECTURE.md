# LAMP Stack Disaster Recovery Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    DISASTER RECOVERY ARCHITECTURE                       │
└─────────────────────────────────────────────────────────────────────────────────────────┘

Primary Region (eu-west-1)                    │                DR Region (us-east-1)
                                              │
┌──────────────────────────────────────────┐  │  ┌──────────────────────────────────────────┐
│                 VPC                      │  │  │                 VPC                      │
│               10.0.0.0/16                │  │  │               10.1.0.0/16                │
│                                          │  │  │                                          │
│  ┌─────────────────────────────────────┐ │  │  │  ┌─────────────────────────────────────┐ │
│  │           Public Subnets            │ │  │  │  │           Public Subnets            │ │
│  │                                     │ │  │  │  │                                     │ │
│  │  ┌─────────────────────────────┐    │ │  │  │  │  ┌─────────────────────────────┐    │ │
│  │  │     Application LB (ALB)    │    │ │  │  │  │  │     Application LB (ALB)    │    │ │
│  │  │    54.171.123.30 (active)   │    │ │  │  │  │  │      (ready, inactive)      │    │ │
│  │  └─────────────────────────────┘    │ │  │  │  │  └─────────────────────────────┘    │ │
│  └─────────────────────────────────────┘ │  │  │  └─────────────────────────────────────┘ │
│                                          │  │  │                                          │
│  ┌─────────────────────────────────────┐ │  │  │  ┌─────────────────────────────────────┐ │
│  │          Private Subnets            │ │  │  │  │          Private Subnets            │ │
│  │                                     │ │  │  │  │                                     │ │
│  │  ┌─────────────────────────────┐    │ │  │  │  │  ┌─────────────────────────────┐    │ │
│  │  │       ECS Cluster           │    │ │  │  │  │  │       ECS Cluster           │    │ │
│  │  │    ┌─────────────────────┐   │    │ │  │  │  │  │    ┌─────────────────────┐   │    │ │
│  │  │    │   LAMP Container    │   │    │ │  │  │  │  │    │   LAMP Container    │   │    │ │
│  │  │    │   (2 tasks active)  │   │    │ │  │  │  │  │    │   (0 tasks - pilot) │   │    │ │
│  │  │    └─────────────────────┘   │    │ │  │  │  │  │    └─────────────────────┘   │    │ │
│  │  └─────────────────────────────┘    │ │  │  │  │  └─────────────────────────────┘    │ │
│  └─────────────────────────────────────┘ │  │  │  └─────────────────────────────────────┘ │
│                                          │  │  │                                          │
│  ┌─────────────────────────────────────┐ │  │  │  ┌─────────────────────────────────────┐ │
│  │         Database Subnets            │ │  │  │  │         Database Subnets            │ │
│  │                                     │ │  │  │  │                                     │ │
│  │  ┌─────────────────────────────┐    │ │  │  │  │  ┌─────────────────────────────┐    │ │
│  │  │     RDS MySQL (Primary)     │    │ │  │  │  │  │   RDS MySQL (Read Replica)  │    │ │
│  │  │  test-db.c7c22480exdf...    │────┼─┼──┼──┼──┼──│►  lamp-app-dr-read-replica  │    │ │
│  │  │      (Active Database)      │    │ │  │  │  │  │     (Standby - Ready)       │    │ │
│  │  └─────────────────────────────┘    │ │  │  │  │  └─────────────────────────────┘    │ │
│  └─────────────────────────────────────┘ │  │  │  └─────────────────────────────────────┘ │
│                                          │  │  │                                          │
└──────────────────────────────────────────┘  │  └──────────────────────────────────────────┘
                                              │
┌──────────────────────────────────────────┐  │  ┌──────────────────────────────────────────┐
│              S3 Storage                  │  │  │              S3 Storage                  │
│                                          │  │  │                                          │
│  ┌─────────────────────────────────────┐ │  │  │  ┌─────────────────────────────────────┐ │
│  │     Primary Assets Bucket          │ │  │  │  │       DR Assets Bucket             │ │
│  │   lamp-app-assets-primary-xxx      │─┼──┼──┼──┼──│►  lamp-app-assets-dr-xxx        │ │
│  │    (Active Storage)                 │ │  │  │  │     (Replicated Storage)           │ │
│  └─────────────────────────────────────┘ │  │  │  └─────────────────────────────────────┘ │
└──────────────────────────────────────────┘  │  └──────────────────────────────────────────┘
                                              │
┌─────────────────────────────────────────────┼─────────────────────────────────────────────┐
│                           MONITORING & ALERTING                                          │
├─────────────────────────────────────────────┼─────────────────────────────────────────────┤
│  CloudWatch Metrics:                        │  CloudWatch Alarms:                        │
│  • RDS Replica Lag                          │  • Replica Lag > 60s                       │
│  • ECS Task Health                          │  • ECS CPU > 80%                           │
│  • ALB Response Times                       │  • ALB Target Health                       │
│  • S3 Replication Status                    │  • S3 Replication Failures                 │
└─────────────────────────────────────────────┼─────────────────────────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │             DNS FAILOVER (Optional)              │
                    │                         │                        │
                    │  Route 53 Health Checks │ Automatic Failover     │
                    │  Primary: 54.171.123.30 │ DR: ALB DNS Name       │
                    └─────────────────────────┼─────────────────────────┘

DISASTER RECOVERY FLOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DETECTION: CloudWatch alarms detect primary region failure
2. ACTIVATION: Run ./scripts/activate-dr.sh
   • Promote RDS Read Replica to Primary
   • Scale ECS Service from 0 → 2 tasks
   • Update database endpoint in SSM
3. DNS CUTOVER: Update DNS to point to DR ALB
4. VALIDATION: Verify application health and data integrity

COST OPTIMIZATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Pilot Light Strategy: ECS tasks = 0 when not in use
• Small RDS instance: db.t3.micro for read replica
• S3 Lifecycle: Old versions → Glacier → Delete
• Estimated monthly cost: ~$75 for full DR readiness

RECOVERY TIME OBJECTIVES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• RTO (Recovery Time Objective): < 15 minutes
• RPO (Recovery Point Objective): < 5 minutes (based on replication lag)
• Application availability during DR: 99.9%

TESTING STRATEGY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Monthly DR tests with ./scripts/test-dr.sh
• Quarterly full failover simulation
• Continuous monitoring with ./scripts/monitor-dr.sh
• Automated alerts via SNS → Email
```

## Key Components Summary

| Component | Primary (eu-west-1) | DR (us-east-1) | Replication Method |
|-----------|--------------------|-----------------|--------------------|
| **ECS** | 2 tasks active | 0 tasks (pilot light) | Task definition sync |
| **RDS** | Primary MySQL | Read replica | Built-in replication |
| **S3** | Primary bucket | Replicated bucket | Cross-region replication |
| **ALB** | Active load balancer | Ready (inactive) | Infrastructure as Code |
| **VPC** | Production network | Mirrored network | Terraform deployment |

## Automation Scripts

- **`activate-dr.sh`**: Complete DR activation (RDS promote + ECS scale)
- **`test-dr.sh`**: Non-disruptive DR testing
- **`monitor-dr.sh`**: Health monitoring and status checks
- **`recover-primary.sh`**: Recovery back to primary region
