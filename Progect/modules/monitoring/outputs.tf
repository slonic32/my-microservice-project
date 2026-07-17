output "monitoring_release_name" {
  description = "Назва Helm-релізу monitoring"
  value       = helm_release.monitoring.name
}

output "monitoring_namespace" {
  description = "Namespace monitoring"
  value       = helm_release.monitoring.namespace
}

output "grafana_service_name" {
  description = "Назва Kubernetes Service Grafana"
  value       = "grafana"
}

output "grafana_admin_username" {
  description = "Ім'я адміністратора Grafana"
  value       = "admin"
}
