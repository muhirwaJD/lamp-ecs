# Application Load Balancer for DR
resource "aws_lb" "dr_alb" {
  provider           = aws.dr
  name               = "${var.app_name}-dr-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dr_alb.id]
  subnets           = [aws_subnet.dr_public_1.id, aws_subnet.dr_public_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "${var.app_name}-dr-alb"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}

# Target Group for DR
resource "aws_lb_target_group" "dr_tg" {
  provider    = aws.dr
  name        = "${var.app_name}-dr-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dr_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/index.php"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.app_name}-dr-tg"
    Environment = var.environment
  }
}

# ALB Listener for DR
resource "aws_lb_listener" "dr_listener" {
  provider          = aws.dr
  load_balancer_arn = aws_lb.dr_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_tg.arn
  }
}
