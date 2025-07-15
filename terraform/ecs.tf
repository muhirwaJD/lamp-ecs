# ECS Cluster for DR
resource "aws_ecs_cluster" "dr_cluster" {
  provider = aws.dr
  name     = "${var.app_name}-dr-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.dr_ecs.name
      }
    }
  }

  tags = {
    Name        = "${var.app_name}-dr-cluster"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}

# CloudWatch Log Group for DR ECS
resource "aws_cloudwatch_log_group" "dr_ecs" {
  provider          = aws.dr
  name              = "/ecs/${var.app_name}-dr-task"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-dr-ecs-logs"
    Environment = var.environment
  }
}

# ECS Task Definition for DR
resource "aws_ecs_task_definition" "dr_task" {
  provider                 = aws.dr
  family                   = "${var.app_name}-dr-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.dr_ecs_execution.arn
  task_role_arn           = aws_iam_role.dr_ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "lamp-app"
      image     = var.container_image
      essential = true
      
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "DB_NAME"
          value = "testdb"
        },
        {
          name  = "DB_HOST"
          value = data.aws_db_instance.dr_read_replica.endpoint
        },
        {
          name  = "DB_USER"
          value = "admin"
        }
      ]
      
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_ssm_parameter.dr_db_password.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dr_ecs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/index.php || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }
    }
  ])

  tags = {
    Name        = "${var.app_name}-dr-task"
    Environment = var.environment
  }
}

# ECS Service for DR (initially with 0 desired count)
resource "aws_ecs_service" "dr_service" {
  provider        = aws.dr
  name            = "${var.app_name}-dr-service"
  cluster         = aws_ecs_cluster.dr_cluster.id
  task_definition = aws_ecs_task_definition.dr_task.arn
  desired_count   = var.dr_ecs_desired_count  # Pilot light - keep at 0 to save costs
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.dr_private_1.id, aws_subnet.dr_private_2.id]
    security_groups  = [aws_security_group.dr_ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dr_tg.arn
    container_name   = "lamp-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.dr_listener]

  tags = {
    Name        = "${var.app_name}-dr-service"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}
