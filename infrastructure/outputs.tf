output "backstage_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "URL to access Backstage portal"
}

output "ecr_repository_url" {
  value       = module.ecs.ecr_repository_url
  description = "ECR URL to push Docker image"
}

output "ecs_cluster_name" {
  value       = module.ecs.ecs_cluster_name
  description = "ECS cluster name"
}