
output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

output "aurora_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}
