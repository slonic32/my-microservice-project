output "id" {
  description = "ID RDS instance або Aurora cluster"
  value = var.use_aurora ? (
    aws_rds_cluster.aurora[0].id
    ) : (
    aws_db_instance.standard[0].id
  )
}

output "arn" {
  description = "ARN RDS instance або Aurora cluster"
  value = var.use_aurora ? (
    aws_rds_cluster.aurora[0].arn
    ) : (
    aws_db_instance.standard[0].arn
  )
}

output "endpoint" {
  description = "Writer endpoint бази даних"
  value = var.use_aurora ? (
    aws_rds_cluster.aurora[0].endpoint
    ) : (
    aws_db_instance.standard[0].address
  )
}

output "reader_endpoint" {
  description = "Reader endpoint Aurora. Для звичайної RDS повертає null"
  value = var.use_aurora ? (
    aws_rds_cluster.aurora[0].reader_endpoint
  ) : null
}

output "port" {
  description = "Порт бази даних"
  value       = local.database_port
}

output "database_name" {
  description = "Назва початкової бази даних"
  value       = var.db_name
}

output "security_group_id" {
  description = "ID Security Group бази даних"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Назва DB Subnet Group"
  value       = aws_db_subnet_group.default.name
}

output "parameter_group_name" {
  description = "Назва створеної parameter group"
  value = var.use_aurora ? (
    aws_rds_cluster_parameter_group.aurora[0].name
    ) : (
    aws_db_parameter_group.standard[0].name
  )
}

output "engine" {
  description = "Фактичний database engine"
  value       = var.use_aurora ? local.aurora_engine : var.engine
}