# Мій власний мікросервісний проєкт

Це репозиторій для домашнього завдання з Docker: Django + PostgreSQL + Nginx.

## Склад проєкту

- **Django** — вебзастосунок
- **PostgreSQL** — база даних
- **Nginx** — проксі перед Django
- **Docker Compose** — оркестрація сервісів

## Структура

- `django/` — Django-проєкт
- `nginx/nginx.conf` — конфігурація Nginx
- `docker-compose.yml` — опис сервісів
- `.env` — змінні середовища (локально)
- `.env_example` — приклад змінних

## Запуск

1. Створи `.env` на основі `.env_example`:
   ```bash
   cp .env_example .env
   ```

2. Запусти контейнери::
   ```bash
   docker compose up --build
   ```

3. Перевірити:

застосунок: http://localhost
Django напряму: http://localhost:8000

## Зупинка

   ```bash
   docker compose down
   ```

Для видалення  volume БД:

```bash
   docker compose down -v
```