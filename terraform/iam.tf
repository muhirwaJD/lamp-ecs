# IAM Roles and Policies for DR ECS

# ECS Task Execution Role
resource "aws_iam_role" "dr_ecs_execution" {
  provider = aws.dr
  name     = "${var.app_name}-dr-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-dr-ecs-execution-role"
    Environment = var.environment
  }
}

# ECS Task Role
resource "aws_iam_role" "dr_ecs_task" {
  provider = aws.dr
  name     = "${var.app_name}-dr-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-dr-ecs-task-role"
    Environment = var.environment
  }
}

# Attach ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "dr_ecs_execution_policy" {
  provider   = aws.dr
  role       = aws_iam_role.dr_ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for accessing SSM parameters
resource "aws_iam_role_policy" "dr_ecs_ssm_policy" {
  provider = aws.dr
  name     = "${var.app_name}-dr-ecs-ssm-policy"
  role     = aws_iam_role.dr_ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.dr_db_password.arn,
          aws_ssm_parameter.dr_db_host.arn
        ]
      }
    ]
  })
}

# Store database password in SSM Parameter Store
resource "aws_ssm_parameter" "dr_db_password" {
  provider = aws.dr
  name     = "/${var.app_name}/dr/db/password"
  type     = "SecureString"
  value    = var.db_password

  tags = {
    Name        = "${var.app_name}-dr-db-password"
    Environment = var.environment
  }
}

# Store database host in SSM Parameter Store
resource "aws_ssm_parameter" "dr_db_host" {
  provider = aws.dr
  name     = "/${var.app_name}/dr/db/host"
  type     = "String"
  value    = data.aws_db_instance.dr_read_replica.endpoint

  tags = {
    Name        = "${var.app_name}-dr-db-host"
    Environment = var.environment
  }
}
