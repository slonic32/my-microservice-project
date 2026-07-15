# Вказуємо версію Terraform та провайдера AWS
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

# Налаштовуємо AWS провайдер
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host = module.eks.eks_cluster_endpoint

  cluster_ca_certificate = base64decode(
    module.eks.eks_cluster_certificate_authority_data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.eks_cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host = module.eks.eks_cluster_endpoint

    cluster_ca_certificate = base64decode(
      module.eks.eks_cluster_certificate_authority_data
    )

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.eks_cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Підключаємо модуль для S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"   # Шлях до модуля
  bucket_name = var.tf_state_bucket_name # Ім'я S3-бакета
  table_name  = var.tf_lock_table_name   # Ім'я DynamoDB
}

# Підключаємо модуль для VPC
module "vpc" {
  source             = "./modules/vpc" # Шлях до модуля VPC
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_name
  scan_on_push = var.ecr_scan_on_push
}

module "eks" {
  source        = "./modules/eks"
  cluster_name  = "eks-cluster-demo"
  subnet_ids    = module.vpc.private_subnets
  instance_type = "t3.small"
  desired_size  = 2
  max_size      = 3
  min_size      = 1
}

module "jenkins" {
  source            = "./modules/jenkins"
  cluster_name      = module.eks.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  github_username   = var.github_username
  github_token      = var.github_token

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks, terraform_data.update_kubeconfig]
}

module "argo_cd" {
  source        = "./modules/argo_cd"
  namespace     = "argocd"
  chart_version = "5.46.4"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.jenkins]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  create_namespace = false

  depends_on = [module.eks]
}

resource "terraform_data" "update_kubeconfig" {
  triggers_replace = [
    module.eks.eks_cluster_endpoint
  ]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.eks_cluster_name}"
  }

  depends_on = [module.eks]
}