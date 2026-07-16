variable "aws_region" {
  description = "Регіон AWS"
  type        = string
}

variable "tf_state_bucket_name" {
  description = "Назва S3-бакета для Terraform state"
  type        = string
}

variable "tf_lock_table_name" {
  description = "Назва DynamoDB таблиці для блокування state"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR блок для VPC"
  type        = string
}

variable "public_subnets" {
  description = "Список CIDR блоків для публічних підмереж"
  type        = list(string)
}

variable "private_subnets" {
  description = "Список CIDR блоків для приватних підмереж"
  type        = list(string)
}

variable "availability_zones" {
  description = "Список зон доступності"
  type        = list(string)
}

variable "vpc_name" {
  description = "Ім'я VPC"
  type        = string
}

variable "ecr_name" {
  description = "Назва ECR репозиторію"
  type        = string
}

variable "ecr_scan_on_push" {
  description = "Увімкнути сканування образів при push"
  type        = bool
  default     = true
}

variable "github_username" {
  description = "GitHub username for Jenkins"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token for Jenkins"
  type        = string
  sensitive   = true
}

variable "jenkins_admin_username" {
  description = "Jenkins administrator username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins administrator password"
  type        = string
  sensitive   = true
}

variable "rds_use_aurora" {
  description = "Створити Aurora cluster замість звичайної RDS"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "Database engine: postgres або mysql"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Версія database engine"
  type        = string
  default     = null
  nullable    = true
}

variable "rds_parameter_group_family" {
  description = "Parameter group family для обраного engine"
  type        = string
}

variable "rds_instance_class" {
  description = "Клас RDS/Aurora instance"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_multi_az" {
  description = "Увімкнути Multi-AZ для звичайної RDS"
  type        = bool
  default     = false
}

variable "rds_username" {
  description = "Ім'я адміністратора бази даних"
  type        = string
  default     = "postgres"
}

variable "rds_password" {
  description = "Пароль адміністратора бази даних"
  type        = string
  sensitive   = true
}