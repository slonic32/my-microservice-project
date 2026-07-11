output "repository_url" {
  description = "URL ECR репозиторію"
  value       = aws_ecr_repository.main.repository_url
}