# Фінальний DevOps-проєкт на AWS

У проєкті реалізовано повну інфраструктуру для розгортання Django-застосунку в Amazon EKS. AWS-ресурси створюються через Terraform, Jenkins збирає Docker-образ і публікує його в Amazon ECR, а Argo CD автоматично синхронізує Helm chart із Kubernetes-кластером.

Моніторинг кластера забезпечують Prometheus і Grafana. Дані застосунку зберігаються в Amazon RDS for PostgreSQL.

## Використані технології

- Terraform;
- AWS VPC, IAM, EKS, ECR, RDS, S3, DynamoDB та EBS;
- Kubernetes і Helm;
- Jenkins, Kaniko та JCasC;
- Argo CD;
- Prometheus, Grafana та metrics-server;
- Docker, Django та PostgreSQL.

## Архітектура

```text
Developer
    |
    | git push
    v
GitHub repository
    |
    v
Jenkins Pipeline у Amazon EKS
    |
    +--> Kaniko збирає Docker-образ
    |
    +--> образ публікується в Amazon ECR
    |
    +--> Jenkins оновлює image.tag у Helm values.yaml
    |
    +--> Jenkins виконує commit і push у GitHub
                         |
                         v
                      Argo CD
                         |
                         v
              Django Deployment + HPA
                         |
                         v
                 Amazon RDS PostgreSQL

Prometheus <--- EKS metrics ---> Grafana
```

EKS worker nodes і RDS розміщуються у приватних підмережах. Вихід приватних підмереж в інтернет виконується через NAT Gateway. Django, Jenkins та Argo CD доступні через AWS Load Balancer, а Grafana і Prometheus — через port-forward.

## Структура проєкту

```text
.
├── django/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── manage.py
│   └── homework/
└── Progect/
    ├── backend.tf
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    ├── charts/
    │   └── django-app/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │           ├── configmap.yaml
    │           ├── deployment.yaml
    │           ├── hpa.yaml
    │           └── service.yaml
    └── modules/
        ├── argo_cd/
        ├── ecr/
        ├── eks/
        ├── jenkins/
        ├── monitoring/
        ├── rds/
        ├── s3-backend/
        └── vpc/
```

## Передумови

Потрібно встановити:

- AWS CLI;
- Terraform `>= 1.5`;
- kubectl;
- Helm;
- Docker;
- Git.

Налаштуйте AWS credentials і перевірте доступ:

```bash
aws configure
aws sts get-caller-identity
```

Створіть локальний файл зі значеннями Terraform:

```bash
cd Progect
cp terraform.tfvars.example terraform.tfvars
```

Замініть демонстраційні значення `change-me`. Файл `terraform.tfvars` містить секрети, ігнорується Git та не повинен потрапляти в репозиторій.

## Перевірка конфігурації

```bash
terraform fmt -check -recursive
terraform validate

helm lint charts/django-app
helm lint modules/argo_cd/charts
```

Перевірка Django-застосунку:

```bash
cd ..
docker build -t django-app:test ./django

docker run --rm \
  -e DJANGO_SECRET_KEY=test-secret \
  django-app:test \
  python manage.py check
```

## Bootstrap Terraform backend

S3 bucket не може використовуватися як backend до того, як він буде створений. Під час першого запуску тимчасово закоментуйте блок `backend "s3"` у `Progect/backend.tf`.

Після цього виконайте:

```bash
cd Progect
terraform init -reconfigure

terraform plan \
  -target=module.s3_backend \
  -out=backend.tfplan

terraform apply "backend.tfplan"
rm backend.tfplan
```

Поверніть блок `backend "s3"` у `backend.tf` і перенесіть локальний state у S3:

```bash
terraform init -migrate-state
terraform state list
```

Під час запиту про копіювання state введіть `yes`.

## Розгортання інфраструктури

Перевірте повний план:

```bash
terraform validate
terraform plan -out=final-project.tfplan
```

Якщо plan не містить неочікуваного видалення ресурсів, виконайте:

```bash
terraform apply "final-project.tfplan"
rm final-project.tfplan
```

Якщо Kubernetes або Helm providers не можуть підключитися до EKS під час першого запуску, спочатку створіть базову AWS-інфраструктуру:

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

Після підключення до EKS завершіть розгортання:

```bash
terraform apply
```

Якщо AWS-ресурс із таким ім'ям уже існує, але відсутній у Terraform state, його потрібно імпортувати командою `terraform import`, а не створювати повторно або видаляти вручну.

## Перевірка компонентів

```bash
kubectl get nodes
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get pods,svc,hpa -n django
kubectl get pvc -A
helm list --all-namespaces
```

Перевірка metrics-server і HPA:

```bash
kubectl top nodes
kubectl top pods -n django
kubectl get hpa -n django
```

У колонці `TARGETS` HPA повинен відображатися реальний відсоток CPU, а не `<unknown>`.

## Доступ до сервісів

### Django

```bash
kubectl get svc django-app-django -n django
```

Застосунок доступний через hostname у колонці `EXTERNAL-IP`.

### Jenkins

```bash
kubectl port-forward svc/jenkins 8080:80 -n jenkins
```

Адреса: `http://localhost:8080`.

### Argo CD

```bash
kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd
```

Адреса: `https://localhost:8081`, користувач: `admin`.

Початковий пароль:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath='{.data.password}' | base64 -d

echo
```

### Grafana

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Адреса: `http://localhost:3000`, користувач: `admin`. Пароль задається змінною `grafana_admin_password`.

### Prometheus

```bash
kubectl port-forward \
  svc/monitoring-kube-prometheus-prometheus \
  9090:9090 \
  -n monitoring
```

Адреса: `http://localhost:9090`.

## Демонстрація CI/CD

Після зміни Django-застосунку виконайте commit і push у гілку, яку відстежує Jenkins:

```bash
git add django
git commit -m "Test Jenkins CI/CD pipeline"
git push origin main
```

Jenkins автоматично:

1. запускає Kubernetes Agent;
2. збирає образ через Kaniko;
3. публікує новий tag у ECR;
4. змінює `image.tag` у Helm values;
5. виконує Git commit із позначкою `[jenkins]`;
6. виконує push у GitHub.

Перевірте результат:

```bash
aws ecr describe-images \
  --repository-name lesson-7-ecr \
  --region eu-central-1

kubectl get application django-app -n argocd \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision'

kubectl get deployment django-app-django \
  -n django \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

kubectl rollout status deployment/django-app-django \
  -n django \
  --timeout=5m
```

Argo CD Application повинна мати статуси `Synced` і `Healthy`.

## Моніторинг

Модуль `monitoring` встановлює `kube-prometheus-stack`, до складу якого входять:

- Prometheus Operator;
- Prometheus;
- Grafana;
- Alertmanager;
- kube-state-metrics;
- Prometheus Node Exporter;
- готові Kubernetes dashboards і alert rules.

У Grafana можна використати dashboard `Kubernetes / Compute Resources / Cluster` для демонстрації CPU, memory, nodes, namespaces і pods.

## Безпека

- EKS nodes і RDS розміщені у приватних підмережах;
- RDS не має публічного доступу;
- доступ до RDS обмежений Security Group;
- S3 backend використовує versioning, encryption і блокування публічного доступу;
- Jenkins використовує IAM Role for Service Account для роботи з ECR;
- GitHub PAT зберігається в Jenkins Credentials;
- паролі застосунку передаються через Kubernetes Secrets;
- `terraform.tfvars`, `.env`, state і plan-файли не повинні потрапляти в Git.

Секрети зберігаються у Terraform state, тому доступ до S3 bucket потрібно обмежувати через IAM.

## Видалення інфраструктури

Щоб Terraform міг видалити S3 backend і після цього зберегти фінальний state, спочатку перенесіть state назад локально.

1. Тимчасово закоментуйте блок `backend "s3"` у `backend.tf`.
2. Виконайте міграцію:

```bash
terraform init -migrate-state
```

Підтвердьте копіювання state у локальний backend, а потім виконайте:

```bash
terraform destroy
```

Після перевірки видаліть локальні state-файли та переконайтеся в AWS Console, що платні ресурси EKS, EC2, NAT Gateway, Load Balancer, EBS і RDS більше не існують.
