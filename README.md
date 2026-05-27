# SRE Platform

<div align="center">

**[🇬🇧 English](#english) · [🇷🇺 Русский](#russian)**

</div>

---

<a name="english"></a>

# 🇬🇧 English

<div align="right"><a href="#russian">👇 Русский</a></div>

Production-grade self-hosted platform built with modern DevOps/SRE tooling.
Demonstrates end-to-end infrastructure automation: from cloud provisioning to application deployment with full observability.

## Stack

- **Cloud**: Hetzner Cloud
- **IaC**: Terraform with S3 remote state (Hetzner Object Storage)
- **Configuration Management**: Ansible
- **Container Orchestration**: k3s (Kubernetes)
- **Package Manager**: Helm (custom charts)
- **Ingress**: Traefik (built into k3s)
- **TLS**: cert-manager + Let's Encrypt
- **Security**: UFW, fail2ban + Telegram alerts, iptables-persistent
- **Monitoring**: Telegram bots for SSH brute-force alerts and server activity
- **Applications**: n8n (workflow automation)

## Infrastructure

| Server | Role | Type | Location |
|--------|------|------|----------|
| sre-main | Management node (Ansible, Terraform, Helm, kubectl) | cax11 | fsn1 |
| sre-node-1 | k3s master | cax11 | fsn1 |
| sre-node-2 | k3s worker | cax11 | fsn1 |

## Network

| Resource | Value |
|----------|-------|
| Network | 10.0.0.0/16 |
| Subnet | 10.0.1.0/24 |
| sre-node-1 | 10.0.1.10 |
| sre-node-2 | 10.0.1.11 |

## Firewall Rules

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 6443 | TCP | k3s API server |
| 8472 | UDP | Flannel VXLAN (CNI pod networking) |

## Repository Structure

```
sre-platform/
├── terraform/                    # Cloud infrastructure (IaC)
│   ├── main.tf                   # Network, firewall, servers
│   ├── variables.tf              # Input variables
│   ├── backend.tfvars.example    # S3 backend config template
│   └── terraform.tfvars.example  # Hetzner token template
├── ansible/                      # Server configuration
│   ├── inventory.ini             # Server inventory (all nodes)
│   ├── playbook.yml              # Bootstrap: Docker, UFW, fail2ban, Telegram bots
│   ├── k3s.yml                   # k3s master + worker setup
│   ├── helm.yml                  # Helm + kubectl install, kubeconfig fetch
│   ├── cert-manager.yml          # cert-manager + Let's Encrypt ClusterIssuer
│   ├── deploy-apps.yml           # Deploy applications via Helm
│   └── vault.yml.example         # Secrets template
└── helm/
    └── n8n/                      # Custom Helm chart for n8n
        ├── Chart.yaml
        ├── values.yaml           # Default values
        ├── values-prod.yaml.example
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── ingress.yaml
            ├── pvc.yaml
            ├── hpa.yaml
            └── _helpers.tpl
```

## Secrets

Never commit to git:

| File | Contains |
|------|----------|
| `ansible/vault.yml` | Telegram tokens, whitelisted IPs |
| `terraform/terraform.tfvars` | Hetzner Cloud API token |
| `terraform/backend.tfvars` | S3 access key and secret key |
| `helm/n8n/values-prod.yaml` | Domain, production configuration |

Use `.example` files as templates.

## Prerequisites

### 1. Hetzner Object Storage bucket (manual step)

Hetzner does not support creating Object Storage buckets via Terraform or CLI.
Create the bucket manually in the Hetzner Console:

1. Go to `console.hetzner.cloud` → your project → **Object Storage**
2. Click **Create Bucket**
3. Name: `sre-terraform-state`, Location: `Falkenstein (fsn1)`, Visibility: **Private**
4. Go to **S3 Credentials** → **Generate Credentials**
5. Save the Access Key and Secret Key — fill them into `terraform/backend.tfvars`

### 2. Telegram bots

Create two bots via @BotFather in Telegram:
- **Bot 1**: for fail2ban SSH brute-force alerts
- **Bot 2**: for server activity monitoring

Get your Chat ID by sending a message to the bot and opening:
`https://api.telegram.org/botYOUR_TOKEN/getUpdates`

Look for `"chat":{"id":XXXXXXX}` in the response.

### 3. Domain

Add an A record pointing to the public IP of sre-node-1.

## Deployment

### Step 1 — Terraform (provision infrastructure)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
cp backend.tfvars.example backend.tfvars
# Fill in terraform.tfvars with your Hetzner API token
# Fill in backend.tfvars with your S3 credentials
terraform init -backend-config=backend.tfvars
terraform apply
```

### Step 2 — Ansible bootstrap (all nodes)

```bash
cd ansible
cp vault.yml.example vault.yml
# Fill in vault.yml with Telegram tokens and whitelisted IPs
# Update inventory.ini with your actual server IPs
ansible-playbook -i inventory.ini playbook.yml
```

This installs on all nodes: Docker, UFW, fail2ban, iptables-persistent, fail2ban-telegram bot, server-activity-telegram bot.

### Step 3 — k3s cluster

```bash
ansible-playbook -i inventory.ini k3s.yml
```

Installs k3s master on sre-node-1, joins sre-node-2 as worker.

### Step 4 — Helm + kubectl

```bash
ansible-playbook -i inventory.ini helm.yml
```

Installs Helm and kubectl on sre-main, fetches kubeconfig from master.

### Step 5 — cert-manager + TLS

```bash
ansible-playbook -i inventory.ini cert-manager.yml
```

Installs cert-manager and creates a Let's Encrypt ClusterIssuer.

### Step 6 — Deploy applications

```bash
cd helm/n8n
cp values-prod.yaml.example values-prod.yaml
# Fill in values-prod.yaml with your domain
cd ../../ansible
ansible-playbook -i inventory.ini deploy-apps.yml
```

## Security

- **UFW**: only ports 22, 80, 443, 6443, 8472 open; all else denied
- **fail2ban**: bans IPs after repeated SSH failures
- **fail2ban-telegram**: real-time Telegram alerts on every ban event
- **server-activity-telegram**: periodic server activity reports to Telegram
- **iptables-persistent**: firewall rules survive reboots
- **Secrets management**: all tokens and keys stored outside git in vault.yml / tfvars files

<div align="right"><a href="#english">👆 English</a> · <a href="#russian">👇 Русский</a></div>

---

<a name="russian"></a>

# 🇷🇺 Русский

<div align="right"><a href="#english">👆 English</a></div>

Production-grade self-hosted платформа, построенная с использованием современного DevOps/SRE инструментария.
Демонстрирует полную автоматизацию инфраструктуры: от развёртывания облака до деплоя приложений с полноценным мониторингом.

## Стек технологий

- **Cloud**: Hetzner Cloud
- **IaC**: Terraform с S3 remote state (Hetzner Object Storage)
- **Configuration Management**: Ansible
- **Container Orchestration**: k3s (Kubernetes)
- **Package Manager**: Helm (кастомные чарты)
- **Ingress**: Traefik (встроен в k3s)
- **TLS**: cert-manager + Let's Encrypt
- **Безопасность**: UFW, fail2ban + Telegram-уведомления, iptables-persistent
- **Мониторинг**: Telegram-боты для алертов о брутфорсе SSH и активности сервера
- **Приложения**: n8n (автоматизация рабочих процессов)

## Инфраструктура

| Сервер | Роль | Тип | Локация |
|--------|------|-----|---------|
| sre-main | Управляющая нода (Ansible, Terraform, Helm, kubectl) | cax11 | fsn1 |
| sre-node-1 | k3s master | cax11 | fsn1 |
| sre-node-2 | k3s worker | cax11 | fsn1 |

## Сеть

| Ресурс | Значение |
|--------|----------|
| Network | 10.0.0.0/16 |
| Subnet | 10.0.1.0/24 |
| sre-node-1 | 10.0.1.10 |
| sre-node-2 | 10.0.1.11 |

## Правила файрвола

| Порт | Протокол | Назначение |
|------|----------|------------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 6443 | TCP | k3s API сервер |
| 8472 | UDP | Flannel VXLAN (CNI сеть между подами) |

## Структура репозитория

```
sre-platform/
├── terraform/                    # Облачная инфраструктура (IaC)
│   ├── main.tf                   # Сеть, файрвол, серверы
│   ├── variables.tf              # Входные переменные
│   ├── backend.tfvars.example    # Шаблон конфига S3 бэкенда
│   └── terraform.tfvars.example  # Шаблон токена Hetzner
├── ansible/                      # Конфигурация серверов
│   ├── inventory.ini             # Инвентарь серверов (все ноды)
│   ├── playbook.yml              # Bootstrap: Docker, UFW, fail2ban, Telegram боты
│   ├── k3s.yml                   # Установка k3s master + worker
│   ├── helm.yml                  # Установка Helm + kubectl, получение kubeconfig
│   ├── cert-manager.yml          # cert-manager + Let's Encrypt ClusterIssuer
│   ├── deploy-apps.yml           # Деплой приложений через Helm
│   └── vault.yml.example         # Шаблон секретов
└── helm/
    └── n8n/                      # Кастомный Helm чарт для n8n
        ├── Chart.yaml
        ├── values.yaml           # Значения по умолчанию
        ├── values-prod.yaml.example
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── ingress.yaml
            ├── pvc.yaml
            ├── hpa.yaml
            └── _helpers.tpl
```

## Секреты

Никогда не коммитить в git:

| Файл | Содержимое |
|------|------------|
| `ansible/vault.yml` | Telegram токены, разрешённые IP-адреса |
| `terraform/terraform.tfvars` | API токен Hetzner Cloud |
| `terraform/backend.tfvars` | Access key и Secret key для S3 |
| `helm/n8n/values-prod.yaml` | Домен, продовая конфигурация |

Используйте `.example` файлы как шаблоны.

## Предварительные требования

### 1. Hetzner Object Storage bucket (ручной шаг)

Hetzner не поддерживает создание Object Storage бакетов через Terraform или CLI.
Создайте бакет вручную в Hetzner Console:

1. Перейдите на `console.hetzner.cloud` → ваш проект → **Object Storage**
2. Нажмите **Create Bucket**
3. Имя: `sre-terraform-state`, Локация: `Falkenstein (fsn1)`, Видимость: **Private**
4. Перейдите в **S3 Credentials** → **Generate Credentials**
5. Сохраните Access Key и Secret Key — вставьте их в `terraform/backend.tfvars`

### 2. Telegram боты

Создайте два бота через @BotFather в Telegram:
- **Бот 1**: для алертов fail2ban о попытках брутфорса SSH
- **Бот 2**: для мониторинга активности сервера

Узнайте ваш Chat ID — отправьте боту любое сообщение и откройте:
`https://api.telegram.org/botВАШ_ТОКЕН/getUpdates`

Найдите `"chat":{"id":XXXXXXX}` в ответе.

### 3. Домен

Добавьте A-запись, указывающую на публичный IP sre-node-1.

## Деплой

### Шаг 1 — Terraform (развёртывание инфраструктуры)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
cp backend.tfvars.example backend.tfvars
# Заполните terraform.tfvars вашим токеном Hetzner API
# Заполните backend.tfvars вашими S3 credentials
terraform init -backend-config=backend.tfvars
terraform apply
```

### Шаг 2 — Ansible bootstrap (все ноды)

```bash
cd ansible
cp vault.yml.example vault.yml
# Заполните vault.yml токенами Telegram и разрешёнными IP
# Обновите inventory.ini реальными IP адресами серверов
ansible-playbook -i inventory.ini playbook.yml
```

Устанавливает на все ноды: Docker, UFW, fail2ban, iptables-persistent, Telegram-бот fail2ban, Telegram-бот мониторинга активности.

### Шаг 3 — k3s кластер

```bash
ansible-playbook -i inventory.ini k3s.yml
```

Устанавливает k3s master на sre-node-1, подключает sre-node-2 как worker.

### Шаг 4 — Helm + kubectl

```bash
ansible-playbook -i inventory.ini helm.yml
```

Устанавливает Helm и kubectl на sre-main, получает kubeconfig с master-ноды.

### Шаг 5 — cert-manager + TLS

```bash
ansible-playbook -i inventory.ini cert-manager.yml
```

Устанавливает cert-manager и создаёт Let's Encrypt ClusterIssuer.

### Шаг 6 — Деплой приложений

```bash
cd helm/n8n
cp values-prod.yaml.example values-prod.yaml
# Заполните values-prod.yaml вашим доменом
cd ../../ansible
ansible-playbook -i inventory.ini deploy-apps.yml
```

## Безопасность

- **UFW**: открыты только порты 22, 80, 443, 6443, 8472; всё остальное заблокировано
- **fail2ban**: банит IP-адреса после многократных неудачных попыток подключения по SSH
- **fail2ban-telegram**: мгновенные Telegram-уведомления при каждом бане
- **server-activity-telegram**: периодические отчёты об активности сервера в Telegram
- **iptables-persistent**: правила файрвола сохраняются после перезагрузки
- **Управление секретами**: все токены и ключи хранятся вне git в vault.yml / tfvars файлах

<div align="right"><a href="#russian">👆 Наверх</a> · <a href="#english">👆 English</a></div>
