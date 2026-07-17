output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3_backend.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "URL ECR репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN ECR репозиторію"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Назва ECR репозиторію"
  value       = module.ecr.repository_name
}

output "ecr_registry_id" {
  description = "ID ECR реєстру"
  value       = module.ecr.registry_id
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

output "rds_endpoint" {
  description = "Writer endpoint RDS або Aurora"
  value       = module.rds.endpoint
}

output "rds_reader_endpoint" {
  description = "Reader endpoint Aurora"
  value       = module.rds.reader_endpoint
}

output "rds_port" {
  description = "Порт бази даних"
  value       = module.rds.port
}

output "rds_engine" {
  description = "Database engine"
  value       = module.rds.engine
}

output "rds_security_group_id" {
  description = "Security Group ID бази даних"
  value       = module.rds.security_group_id
}

output "monitoring_release" {
  description = "Назва Helm-релізу monitoring"
  value       = module.monitoring.monitoring_release_name
}

output "monitoring_namespace" {
  description = "Namespace monitoring"
  value       = module.monitoring.monitoring_namespace
}

output "grafana_service_name" {
  description = "Назва Kubernetes Service Grafana"
  value       = module.monitoring.grafana_service_name
}
