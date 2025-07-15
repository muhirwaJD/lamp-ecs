# CloudWatch Alarms for Monitoring

# RDS Replication Lag Alarm
resource "aws_cloudwatch_metric_alarm" "dr_rds_replica_lag" {
  provider            = aws.dr
  alarm_name          = "${var.app_name}-dr-rds-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors RDS replica lag"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = data.aws_db_instance.dr_read_replica.db_instance_identifier
  }

  tags = {
    Name        = "${var.app_name}-dr-rds-replica-lag"
    Environment = var.environment
  }
}

# ECS Service CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "dr_ecs_cpu" {
  provider            = aws.dr
  alarm_name          = "${var.app_name}-dr-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    ServiceName = aws_ecs_service.dr_service.name
    ClusterName = aws_ecs_cluster.dr_cluster.name
  }

  tags = {
    Name        = "${var.app_name}-dr-ecs-cpu"
    Environment = var.environment
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "dr_alerts" {
  provider = aws.dr
  name     = "${var.app_name}-dr-alerts"

  tags = {
    Name        = "${var.app_name}-dr-alerts"
    Environment = var.environment
  }
}

# SNS Topic Subscription (replace with your email)
resource "aws_sns_topic_subscription" "dr_email_alerts" {
  provider  = aws.dr
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
