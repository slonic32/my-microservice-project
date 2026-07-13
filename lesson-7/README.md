# Lesson 5 — Terraform IaC (AWS)

## Опис
У цьому завданні налаштовано:
- Terraform backend у S3
- Блокування стейтів через DynamoDB
- Мережеву інфраструктуру (VPC, публічні та приватні підмережі, IGW, NAT, Route Tables)
- ECR-репозиторій для Docker-образів

## Структура проєкту
- `main.tf` — підключення модулів
- `backend.tf` — налаштування Terraform backend (S3 + DynamoDB)
- `outputs.tf` — загальні output-и
- `modules/s3-backend` — модуль S3 + DynamoDB
- `modules/vpc` — модуль VPC
- `modules/ecr` — модуль ECR

## Команди
```bash
terraform init - ініціалізація
terraform plan - перелік змін у стан
terraform apply - зміна стану
terraform destroy - видалення
```

## Модулі

### s3-backend
Створює:
- S3-бакет для Terraform state
- Версіонування S3
- DynamoDB-таблицю для state locking

### vpc
Створює:
- VPC
- 3 публічні та 3 приватні підмережі
- Internet Gateway
- NAT Gateway
- Route Tables для public/private subnet

### ecr
Створює:
- ECR-репозиторій
- Увімкнене сканування образів при push
- Output з URL репозиторію