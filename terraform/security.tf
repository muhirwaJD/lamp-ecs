# Security Groups for DR Environment

# ALB Security Group
resource "aws_security_group" "dr_alb" {
  provider    = aws.dr
  name        = "${var.app_name}-dr-alb-sg"
  description = "Security group for DR ALB"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-dr-alb-sg"
    Environment = var.environment
  }
}

# ECS Security Group
resource "aws_security_group" "dr_ecs" {
  provider    = aws.dr
  name        = "${var.app_name}-dr-ecs-sg"
  description = "Security group for DR ECS tasks"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-dr-ecs-sg"
    Environment = var.environment
  }
}

# RDS Security Group
resource "aws_security_group" "dr_rds" {
  provider    = aws.dr
  name        = "${var.app_name}-dr-rds-sg"
  description = "Security group for DR RDS"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description     = "MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_ecs.id]
  }

  # Allow connection from primary region for replication
  ingress {
    description = "MySQL from Primary Region"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict this to primary RDS subnet CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-dr-rds-sg"
    Environment = var.environment
  }
}
