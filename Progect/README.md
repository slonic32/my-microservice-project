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


# Універсальний Terraform-модуль RDS

## Опис

Модуль створює звичайну Amazon RDS instance або Amazon Aurora cluster залежно від змінної `use_aurora`.

Модуль підтримує:

- PostgreSQL;
- MySQL;
- Aurora PostgreSQL;
- Aurora MySQL;
- DB Subnet Group;
- Security Group;
- DB Parameter Group;
- Aurora Cluster Parameter Group;
- Multi-AZ для звичайної RDS;
- Aurora writer і reader instances;
- storage encryption;
- automated backups.

## Логіка створення

```text
use_aurora = false
        |
        v
aws_db_instance
        +
aws_db_parameter_group

use_aurora = true
        |
        v
aws_rds_cluster
        +
writer instance
        +
reader instances
        +
aws_rds_cluster_parameter_group
```

В обох випадках створюються:

```text
aws_db_subnet_group
aws_security_group
```

## Приклад використання

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false

  engine                 = "postgres"
  engine_version         = null
  parameter_group_family = "postgres17"
  instance_class         = "db.t3.medium"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "myapp"
  username = "postgres"
  password = var.rds_password

  vpc_id    = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_cidr_blocks = [
    var.vpc_cidr_block
  ]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Основні змінні

| Змінна | Тип | Default | Опис |
|---|---|---:|---|
| `name` | `string` | — | Назва instance або cluster |
| `use_aurora` | `bool` | `false` | Створити Aurora замість RDS |
| `engine` | `string` | `postgres` | `postgres` або `mysql` |
| `engine_version` | `string` | `null` | Версія engine |
| `parameter_group_family` | `string` | — | Family parameter group |
| `instance_class` | `string` | `db.t3.medium` | Клас instance |
| `allocated_storage` | `number` | `20` | Диск звичайної RDS |
| `max_allocated_storage` | `number` | `0` | Максимальний autoscaling диска |
| `db_name` | `string` | — | Назва бази |
| `username` | `string` | — | Ім’я адміністратора |
| `password` | `string` | — | Пароль адміністратора |
| `vpc_id` | `string` | — | ID VPC |
| `subnet_ids` | `list(string)` | — | Підмережі DB Subnet Group |
| `allowed_cidr_blocks` | `list(string)` | `[]` | Дозволені CIDR |
| `allowed_security_group_ids` | `list(string)` | `[]` | Дозволені Security Groups |
| `publicly_accessible` | `bool` | `false` | Публічна доступність |
| `multi_az` | `bool` | `false` | Multi-AZ для звичайної RDS |
| `aurora_replica_count` | `number` | `1` | Кількість Aurora readers |
| `backup_retention_period` | `number` | `7` | Тривалість backup |
| `skip_final_snapshot` | `bool` | `true` | Не створювати final snapshot |
| `deletion_protection` | `bool` | `false` | Захист від видалення |
| `parameters` | `map(string)` | `{}` | Додаткові DB parameters |
| `tags` | `map(string)` | `{}` | Tags ресурсів |

## Зміна типу бази

### PostgreSQL RDS

```hcl
use_aurora             = false
engine                 = "postgres"
parameter_group_family = "postgres17"
```

### MySQL RDS

```hcl
use_aurora             = false
engine                 = "mysql"
parameter_group_family = "mysql8.0"
```

### Aurora PostgreSQL

```hcl
use_aurora             = true
engine                 = "postgres"
parameter_group_family = "aurora-postgresql17"
```

### Aurora MySQL

```hcl
use_aurora             = true
engine                 = "mysql"
parameter_group_family = "aurora-mysql8.0"
```

## Базові параметри

Для PostgreSQL модуль встановлює:

```text
max_connections
log_statement
work_mem
```

Для MySQL використовуються сумісні аналоги:

```text
max_connections
slow_query_log
long_query_time
```

Додаткові або перевизначені параметри передаються через:

```hcl
parameters = {
  max_connections = "300"
}
```

## Перевірка

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

Після створення:

```bash
terraform output rds_endpoint
terraform output rds_port
terraform output rds_engine
```

Перевірка через AWS CLI:

```bash
aws rds describe-db-instances
aws rds describe-db-clusters
aws rds describe-db-subnet-groups
aws rds describe-db-parameter-groups
aws rds describe-db-cluster-parameter-groups
```

## Видалення

```bash
terraform destroy
```

Якщо `deletion_protection = true`, перед видаленням потрібно змінити значення на `false` і виконати `terraform apply`.