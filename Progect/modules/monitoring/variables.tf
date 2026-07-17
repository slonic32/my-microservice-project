variable "name" {
  description = "Назва Helm-релізу monitoring"
  type        = string
  default     = "monitoring"
}

variable "namespace" {
  description = "Kubernetes namespace для monitoring"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Версія Helm chart kube-prometheus-stack"
  type        = string
  default     = "87.12.2"
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  type        = string
  sensitive   = true
}
