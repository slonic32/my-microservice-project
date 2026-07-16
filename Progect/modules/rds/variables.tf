variable "name" {
  description = "Назва RDS instance або Aurora cluster"
  type        = string
}

variable "use_aurora" {
  description = "Створити Aurora cluster замість звичайної RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Тип бази даних: postgres або mysql"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "Змінна engine повинна мати значення postgres або mysql."
  }
}

variable "engine_version" {
  description = "Версія database engine. Якщо null, AWS вибере версію за замовчуванням"
  type        = string
  default     = null
  nullable    = true
}

variable "parameter_group_family" {
  description = "Parameter group family, наприклад postgres17, mysql8.0, aurora-postgresql17 або aurora-mysql8.0"
  type        = string
}

variable "instance_class" {
  description = "Клас RDS або Aurora instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Розмір диска звичайної RDS у GiB. Для Aurora не використовується"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage повинен бути не менше 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Максимальний розмір диска для autoscaling звичайної RDS. 0 вимикає autoscaling"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Тип сховища звичайної RDS"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Увімкнути шифрування сховища"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Назва початкової бази даних"
  type        = string
}

variable "username" {
  description = "Ім'я адміністратора бази даних"
  type        = string
}

variable "password" {
  description = "Пароль адміністратора бази даних"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID VPC для database security group"
  type        = string
}

variable "subnet_ids" {
  description = "Список subnet IDs для DB Subnet Group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Для DB Subnet Group потрібно щонайменше дві підмережі."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR-блоки, яким дозволено підключення до бази даних"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups, яким дозволено підключення до бази даних"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Надати database instance публічну адресу"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ для звичайної RDS. Для Aurora не використовується"
  type        = bool
  default     = false
}

variable "aurora_replica_count" {
  description = "Кількість Aurora reader instances на додаток до writer"
  type        = number
  default     = 1

  validation {
    condition     = var.aurora_replica_count >= 0
    error_message = "aurora_replica_count не може бути від'ємним."
  }
}

variable "backup_retention_period" {
  description = "Кількість днів зберігання автоматичних backup"
  type        = number
  default     = 7

  validation {
    condition = (
      var.backup_retention_period >= 0 &&
      var.backup_retention_period <= 35
    )
    error_message = "backup_retention_period повинен бути від 0 до 35."
  }
}

variable "skip_final_snapshot" {
  description = "Не створювати final snapshot під час видалення"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Захистити базу даних від випадкового видалення"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Застосовувати зміни одразу, без очікування maintenance window"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "Додаткові параметри parameter group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags для ресурсів модуля"
  type        = map(string)
  default     = {}
}