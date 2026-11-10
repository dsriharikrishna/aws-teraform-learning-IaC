output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB to access the application"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group (passed to ECS service)"
  value       = aws_lb_target_group.this.arn
}

