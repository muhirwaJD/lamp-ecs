# DB Subnet Group for DR
resource "aws_db_subnet_group" "dr_db_subnet_group" {
  provider   = aws.dr
  name       = "${var.app_name}-dr-db-subnet-group"
  subnet_ids = [aws_subnet.dr_db_1.id, aws_subnet.dr_db_2.id]

  tags = {
    Name        = "${var.app_name}-dr-db-subnet-group"
    Environment = var.environment
  }
}

# Data source to fetch the manually created RDS Read Replica
data "aws_db_instance" "dr_read_replica" {
  provider                   = aws.dr
  db_instance_identifier     = "lamp-app-dr-read-replica"
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  provider = aws.dr
  name     = "${var.app_name}-dr-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-dr-rds-monitoring-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  provider   = aws.dr
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
