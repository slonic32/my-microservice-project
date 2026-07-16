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

variable "jenkins_admin_username" {
  description = "Jenkins administrator username"
  type        = string
}

variable "jenkins_admin_password" {
  description = "Jenkins administrator password"
  type        = string
  sensitive   = true
}