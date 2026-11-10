output "media_bucket_name" {
  description = "The name of the created S3 Media bucket"
  value       = module.media_bucket.bucket_id
}

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2_server.public_ip
}

output "ec2_web_url" {
  description = "Web address of the EC2 server"
  value       = "http://${module.ec2_server.public_ip}"
}

output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "Connection endpoint of the RDS database"
  value       = module.rds.db_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN where RDS credentials are saved"
  value       = module.rds.secret_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS Fargate cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS Fargate service"
  value       = module.ecs.service_name
}
