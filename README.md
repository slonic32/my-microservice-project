# Django CI/CD — Jenkins, Terraform, Helm та Argo CD

Навчальний DevOps-проєкт, у якому реалізовано повний CI/CD-процес для Django-застосунку в Amazon EKS.

Інфраструктура створюється через Terraform. Jenkins запускає Kubernetes Agent із Kaniko, збирає Docker-образ, публікує його в Amazon ECR та оновлює тег образу в Helm chart. Argo CD відстежує зміни в Git і автоматично синхронізує застосунок у кластері.

## Використані технології

- Terraform;
- AWS VPC, EKS, ECR, IAM, S3, DynamoDB та EBS;
- Docker і Kaniko;
- Kubernetes та Helm;
- Jenkins;
- Argo CD;
- Django і PostgreSQL.

## Структура проєкту

```text
.
├── django/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── manage.py
│   └── homework/
└── Progect/
    ├── main.tf
    ├── backend.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars
    ├── charts/
    │   └── django-app/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │           ├── deployment.yaml
    │           ├── service.yaml
    │           ├── configmap.yaml
    │           ├── secret.yaml
    │           └── hpa.yaml
    └── modules/
        ├── s3-backend/
        ├── vpc/
        ├── ecr/
        ├── eks/
        ├── jenkins/
        └── argo_cd/
```

## Схема CI/CD

```text
Developer
    |
    | git push
    v
GitHub repository
    |
    v
Jenkins Pipeline (Kubernetes Agent)
    |
    +--> Kaniko збирає образ із django/Dockerfile
    |
    +--> Jenkins публікує образ в Amazon ECR
    |
    +--> Jenkins змінює image.tag у Helm values.yaml
    |
    +--> Jenkins виконує commit і push у main
                         |
                         v
                      Argo CD
                         |
                         | автоматична синхронізація
                         v
                 Helm chart у Amazon EKS
                         |
                         v
                  Django Deployment + HPA
```

## Як працює pipeline

1. Розробник виконує push у гілку `main`.
2. Jenkins запускає agent pod із контейнерами Kaniko та Git.
3. Kaniko збирає Docker-образ без Docker daemon і публікує його в ECR із тегом `v1.0.BUILD_NUMBER`.
4. Jenkins клонує GitOps-репозиторій та оновлює `image.tag` у `Progect/charts/django-app/values.yaml`.
5. Jenkins комітить зміну та виконує push у `main`.
6. Argo CD знаходить новий commit і автоматично застосовує Helm chart у namespace `django`.
7. HPA масштабує Django pods на основі використання CPU.

## Передумови

Потрібно встановити:

- AWS CLI;
- Terraform `>= 1.5`;
- kubectl;
- Helm;
- Docker;
- Git.

Також потрібен AWS account і налаштовані credentials:

```bash
aws configure
aws sts get-caller-identity
```

Скопіюйте приклад Terraform-змінних і перевірте значення:

```bash
cd Progect
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` не повинен містити секретні ключі AWS і не повинен потрапляти в Git.

## Перевірка конфігурації

### Terraform

```bash
cd Progect
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

### Helm chart Django

```bash
helm lint Progect/charts/django-app
helm template django-app Progect/charts/django-app --namespace django
```

Після підключення до кластера:

```bash
helm template django-app Progect/charts/django-app \
  --namespace django \
  | kubectl apply --dry-run=client -f -
```

### Helm chart Argo CD Applications

```bash
helm lint Progect/modules/argo_cd/charts
helm template argo-apps Progect/modules/argo_cd/charts --namespace argocd
```

### Docker і Django

```bash
docker build -t django-app:test ./django

docker run --rm \
  -e DJANGO_SECRET_KEY=test-secret \
  django-app:test \
  python manage.py check
```

## Створення інфраструктури

### 1. Bootstrap Terraform backend

S3 bucket не може бути backend до того, як його буде створено. Для першого запуску тимчасово закоментуйте блок `backend "s3"` у `Progect/backend.tf`, а потім виконайте:

```bash
cd Progect
terraform init
terraform apply -target=module.s3_backend
```

Поверніть блок backend у `backend.tf` і перенесіть локальний state у S3:

```bash
terraform init -migrate-state
```

### 2. Створення AWS-інфраструктури та EKS

Спочатку створіть AWS-ресурси та кластер:

```bash
terraform apply \
  -target=module.vpc \
  -target=module.ecr \
  -target=module.eks
```

Налаштуйте kubeconfig:

```bash
AWS_REGION=$(grep aws_region terraform.tfvars | awk -F'"' '{print $2}')
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

kubectl get nodes
```

Після підключення до EKS встановіть Jenkins, metrics-server, Argo CD та Argo CD Application:

```bash
terraform apply
```

## Налаштування Jenkins

## Налаштування Jenkins

Jenkins встановлюється через Terraform і Helm. Адміністративні дані та GitHub credential передаються через Kubernetes Secrets.

Перевірка Jenkins:

```bash
kubectl get pods,svc,pvc -n jenkins
helm list -n jenkins
```

Pipeline job `goit-django-docker` автоматично створюється через Jenkins Configuration as Code та використовує `django/Jenkinsfile`.
GitHub credential має ID `github-token` і створюється через JCasC із даних Kubernetes Secret. Ручне налаштування через Jenkins UI не потрібне.

## Доступ до Argo CD

Перевірте сервіс:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

Отримайте початковий пароль адміністратора:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" \
  | base64 -d

echo
```

Логін адміністратора:

```text
admin
```

## Перевірка повного CI/CD-процесу

Після зміни Django-застосунку виконайте:

```bash
git add django
git commit -m "Test Jenkins CI/CD pipeline"
git push origin main
```

Перевірте, що новий образ з'явився в ECR:

```bash
aws ecr describe-images \
  --repository-name lesson-7-ecr \
  --region eu-central-1
```

Перевірте Argo CD та Django:

```bash
kubectl get applications -n argocd
kubectl describe application django-app -n argocd

kubectl get pods -n django
kubectl get svc -n django
kubectl get hpa -n django

kubectl rollout status deployment/django-app-django -n django
```

Перевірте metrics-server:

```bash
kubectl top nodes
kubectl top pods -n django
```

У `kubectl get hpa -n django` колонка `TARGETS` повинна містити реальний відсоток, наприклад `5%/70%`, а не `<unknown>/70%`.

## Доступ до Django

Отримайте зовнішню адресу LoadBalancer:

```bash
kubectl get svc django-app-django -n django
```

Застосунок буде доступний за адресою:

```text
http://EXTERNAL-IP
```

## Зупинка та очищення

Тимчасово зупинити Django pods:

```bash
kubectl scale deployment django-app-django --replicas=0 -n django
```

Відновити роботу:

```bash
kubectl scale deployment django-app-django --replicas=2 -n django
```

Повністю видалити створену Terraform інфраструктуру:

```bash
cd Progect
terraform destroy
```

S3 bucket із Terraform state краще видаляти окремо після видалення основної інфраструктури та збереження потрібної копії state.

## Безпека

- паролі та ключі застосунку зберігаються в Kubernetes Secret, а не ConfigMap;
- Jenkins використовує IAM Role for Service Account для push образів у ECR;
- GitHub PAT зберігається в Jenkins Credentials;
- секрети, `.env`, `terraform.tfvars` і локальний Terraform state не повинні потрапляти в Git;
- демонстраційні значення `change-me` потрібно замінити перед реальним запуском.
