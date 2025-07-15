# Route 53 Hosted Zone (if you want to use a custom domain)
# Uncomment and configure if you have a domain
/*
resource "aws_route53_zone" "main" {
  provider = aws.primary
  name     = "yourdomain.com"

  tags = {
    Name        = "${var.app_name}-hosted-zone"
    Environment = var.environment
  }
}

# Health Check for Primary Region
resource "aws_route53_health_check" "primary" {
  provider                            = aws.primary
  fqdn                                = aws_lb.primary_alb.dns_name  # You would need to add this resource
  port                                = 80
  type                                = "HTTP"
  resource_path                       = "/index.php"
  failure_threshold                   = 3
  request_interval                    = 30

  tags = {
    Name = "${var.app_name}-primary-health-check"
  }
}

# Primary Record with Failover
resource "aws_route53_record" "primary" {
  provider = aws.primary
  zone_id  = aws_route53_zone.main.zone_id
  name     = "www"
  type     = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = aws_lb.primary_alb.dns_name  # You would need to add this resource
    zone_id                = aws_lb.primary_alb.zone_id
    evaluate_target_health = true
  }
}

# DR Record with Failover
resource "aws_route53_record" "dr" {
  provider = aws.dr
  zone_id  = aws_route53_zone.main.zone_id
  name     = "www"
  type     = "A"

  set_identifier = "dr"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.dr_alb.dns_name
    zone_id                = aws_lb.dr_alb.zone_id
    evaluate_target_health = true
  }
}
*/
