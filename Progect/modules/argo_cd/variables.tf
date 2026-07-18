variable "name" {
  description = "Назва Helm-релізу"
  type        = string
  default     = "argo-cd"
}

variable "namespace" {
  description = "K8s namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Argo CD чарта"
  type        = string
  default     = "5.46.4"
}

variable "kubeconfig" {
  description = "Шлях до kubeconfig файлу"
  type        = string
  default     = "~/.kube/config"
}

variable "ecr_repository_url" {
  description = "URL ECR репозиторію для Django application"
  type        = string
}
