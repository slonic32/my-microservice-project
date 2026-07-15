variable "ecr_name" {
  description = "Назва ECR репозиторію"
  type        = string
}

variable "scan_on_push" {
  description = "Увімкнути сканування образів при push"
  type        = bool
  default     = true
}