output "ecs_execution_role_arn" {
  description = "ARN of ECS Task Execution Role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS Task Role"
  value       = aws_iam_role.ecs_task_role.arn
}

