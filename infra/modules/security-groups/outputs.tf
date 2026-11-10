output "ec2_security_group_id" {
  description = "Security Group ID for EC2"
  value       = aws_security_group.ec2.id
}

output "alb_security_group_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security Group ID for App / ECS"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security Group ID for Database"
  value       = aws_security_group.db.id
}
