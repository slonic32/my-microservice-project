variable "kubeconfig" {
  description = "Шлях до kubeconfig файлу"
  type        = string
  default     = "~/.kube/config"
}

variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN для IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL для IRSA"
  type        = string
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