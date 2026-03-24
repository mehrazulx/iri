
output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.ECS_NLB.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}


output "ecs_task_role_arn" {
  value = aws_iam_role.existing_ecs_role.arn
}

output "provider_service_name" {
  value = aws_vpc_endpoint_service.Endservice.service_name
}

