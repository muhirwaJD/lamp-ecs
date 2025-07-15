# Outputs for important resource information

output "dr_alb_dns_name" {
  description = "DNS name of the DR Application Load Balancer"
  value       = aws_lb.dr_alb.dns_name
}

output "dr_alb_zone_id" {
  description = "Zone ID of the DR Application Load Balancer"
  value       = aws_lb.dr_alb.zone_id
}

output "dr_rds_endpoint" {
  description = "RDS read replica endpoint in DR region"
  value       = data.aws_db_instance.dr_read_replica.endpoint
}

output "dr_ecs_cluster_name" {
  description = "Name of the DR ECS cluster"
  value       = aws_ecs_cluster.dr_cluster.name
}

output "dr_ecs_service_name" {
  description = "Name of the DR ECS service"
  value       = aws_ecs_service.dr_service.name
}

output "primary_s3_bucket" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary_assets.bucket
}

output "dr_s3_bucket" {
  description = "Name of the DR S3 bucket"
  value       = aws_s3_bucket.dr_assets.bucket
}

output "dr_vpc_id" {
  description = "ID of the DR VPC"
  value       = aws_vpc.dr_vpc.id
}
