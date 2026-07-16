# Lesson 7 — Terraform + EKS + ECR + Helm

## Опис

У цьому завданні реалізовано повний базовий цикл деплою Django-застосунку в AWS Kubernetes:

- створення інфраструктури через Terraform;
- створення ECR-репозиторію для Docker-образу;
- пуш Docker-образу в ECR;
- деплой застосунку через Helm chart;
- налаштування Horizontal Pod Autoscaler (HPA).

---

## Структура каталогу

- `main.tf` — підключення модулів
- `backend.tf` — remote backend (S3 + DynamoDB)
- `variables.tf` — опис змінних
- `outputs.tf` — outputs
- `terraform.tfvars` — значення змінних
- `modules/s3-backend` — S3 bucket + DynamoDB lock table
- `modules/vpc` — VPC, subnets, routes, IGW, NAT
- `modules/ecr` — ECR repository
- `modules/eks` — EKS cluster + node group
- `charts/django-app` — Helm chart

---

## Що має бути в Helm chart

- `templates/deployment.yaml`
- `templates/service.yaml`
- `templates/hpa.yaml`
- `templates/configmap.yaml`
- `templates/secret.yaml`
- `values.yaml`

Ключові параметри в `values.yaml`, які важливі для наступних тем:

- `image.repository`
- `image.tag`
- `resources.requests.cpu`
- `autoscaling.minReplicas`
- `autoscaling.maxReplicas`
- `autoscaling.targetCPUUtilizationPercentage`

---

## Команди

### 1. Перевірка Terraform-конфігурації

```bash
cd lesson-7
terraform fmt -check
terraform init
terraform validate
terraform plan 
```

### 2. Створення інфраструктури

```bash
terraform apply 
```

### 3. Налаштування доступу до EKS

```bash
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
AWS_REGION=$(grep aws_region terraform.tfvars | awk -F'"' '{print $2}')
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
kubectl get nodes
```

### 4. Build і push Docker-образу в ECR

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$(echo "$ECR_URL" | cut -d'/' -f1)"

cd ..
docker build -t django-app:latest ./django
docker tag django-app:latest "$ECR_URL"":latest"
docker push "$ECR_URL"":latest"
```

### 5. Деплой застосунку через Helm

```bash
cd lesson-7/charts/django-app
helm lint .
helm template .
helm upgrade --install django-app . -n django --create-namespace
```

### 6. Перевірка стану після деплою

```bash
kubectl get pods -n django
kubectl get svc -n django
kubectl get hpa -n django
```

---

## Перевірка рендерингу Helm-шаблонів

```bash
helm template . | kubectl apply --dry-run=client --validate=false -f -
```

---

## Доступ до застосунку

```bash
kubectl get svc -n django
```

Відкрити в браузері:

```text
http://<EXTERNAL-IP>
```

---

## Очищення ресурсів AWS (щоб не витрачати кошти)

### Видалити основні платні ресурси

```bash
cd lesson-7
terraform destroy 
```
