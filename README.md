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
- **Applications**: n8n (workflow automation), pgAdmin (PostgreSQL management), PostgreSQL (database)

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

    sre-platform/
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── backend.tfvars.example
    │   └── terraform.tfvars.example
    ├── ansible/
    │   ├── roles/
    │   │   └── common/
    │   │       └── tasks/
    │   │           └── main.yml
    │   ├── inventory.ini.example
    │   ├── playbook.yml
    │   ├── k3s.yml
    │   ├── helm.yml
    │   ├── cert-manager.yml
    │   ├── deploy-apps.yml
    │   └── vault.yml.example
    └── helm/
        ├── n8n/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       ├── pvc.yaml
        │       ├── hpa.yaml
        │       └── _helpers.tpl
        ├── pgadmin/
        │   ├── Chart.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       └── pvc.yaml
        └── postgres/
            ├── Chart.yaml
            ├── values-prod.yaml.example
            └── templates/
                ├── statefulset.yaml
                ├── service.yaml
                ├── secret.yaml
                └── pvc.yaml

## Secrets

Never commit to git:

| File | Contains |
|------|----------|
| ansible/vault.yml | Telegram tokens, whitelisted IPs |
| ansible/inventory.ini | Real server IP addresses |
| terraform/terraform.tfvars | Hetzner Cloud API token |
| terraform/backend.tfvars | S3 access key and secret key |
| helm/n8n/values-prod.yaml | Domain, production configuration |
| helm/pgadmin/values.yaml | Domain, pgAdmin credentials |
| helm/postgres/values.yaml | Database name, username, password |

Use .example files as templates.

## Prerequisites

### 0. Management node (sre-main)

**Terraform:**

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform

**Ansible:**

    sudo apt update && sudo apt install -y ansible

**SSH key:**

    ssh-keygen -t ed25519 -C "sre-vps" -f ~/.ssh/id_ed25519
    cat ~/.ssh/id_ed25519.pub

**Clone the repository:**

    git clone https://github.com/Oni-Wan-Shinobi/sre-platform.git
    cd sre-platform

### 1. Hetzner Object Storage bucket (manual step)

1. Go to console.hetzner.cloud → your project → Object Storage
2. Click Create Bucket
3. Name: sre-terraform-state, Location: Falkenstein (fsn1), Visibility: Private
4. Go to S3 Credentials → Generate Credentials
5. Save the Access Key and Secret Key — fill them into terraform/backend.tfvars

### 2. Telegram bots

Create two bots via @BotFather in Telegram:
- Bot 1: for fail2ban SSH brute-force alerts
- Bot 2: for server activity monitoring

Get your Chat ID by sending a message to the bot and opening:
https://api.telegram.org/botYOUR_TOKEN/getUpdates

Look for "chat":{"id":XXXXXXX} in the response.

### 3. Domain

Add an A record pointing to the public IP of sre-node-1.

## Deployment

### Step 1 — Terraform

    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    cp backend.tfvars.example backend.tfvars
    terraform init -backend-config=backend.tfvars
    terraform apply

### Step 2 — Ansible bootstrap

    cd ansible
    cp vault.yml.example vault.yml
    cp inventory.ini.example inventory.ini
    ansible-playbook -i inventory.ini playbook.yml

Installs on all nodes: Docker, UFW, fail2ban, iptables-persistent, fail2ban-telegram bot, server-activity-telegram bot.

### Step 3 — k3s cluster

    ansible-playbook -i inventory.ini k3s.yml

Installs k3s master on sre-node-1, joins sre-node-2 as worker.

### Step 4 — Helm + kubectl

    ansible-playbook -i inventory.ini helm.yml

Installs Helm and kubectl on sre-main, fetches kubeconfig from master.

### Step 5 — cert-manager + TLS

    ansible-playbook -i inventory.ini cert-manager.yml

Installs cert-manager and creates a Let's Encrypt ClusterIssuer.

### Step 6 — Deploy applications

    cd helm/n8n
    cp values-prod.yaml.example values-prod.yaml
    cd ../pgadmin
    cp values-prod.yaml.example values.yaml
    cd ../postgres
    cp values-prod.yaml.example values.yaml
    cd ../../ansible
    ansible-playbook -i inventory.ini deploy-apps.yml

Manual Helm deploys:

    helm upgrade --install pgadmin ~/sre-platform/helm/pgadmin --namespace default
    helm upgrade --install postgres ~/sre-platform/helm/postgres --namespace default

## Security

- **UFW**: only ports 22, 80, 443, 6443, 8472 open; all else denied
- **fail2ban**: bans IPs after repeated SSH failures
- **fail2ban-telegram**: real-time Telegram alerts on every ban event
- **server-activity-telegram**: periodic server activity reports to Telegram
- **iptables-persistent**: firewall rules survive reboots
- **Terraform S3 backend**: state stored remotely in Hetzner Object Storage
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
- **Приложения**: n8n (автоматизация рабочих процессов), pgAdmin (управление PostgreSQL), PostgreSQL (база данных)

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

    sre-platform/
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── backend.tfvars.example
    │   └── terraform.tfvars.example
    ├── ansible/
    │   ├── roles/
    │   │   └── common/
    │   │       └── tasks/
    │   │           └── main.yml
    │   ├── inventory.ini.example
    │   ├── playbook.yml
    │   ├── k3s.yml
    │   ├── helm.yml
    │   ├── cert-manager.yml
    │   ├── deploy-apps.yml
    │   └── vault.yml.example
    └── helm/
        ├── n8n/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       ├── pvc.yaml
        │       ├── hpa.yaml
        │       └── _helpers.tpl
        ├── pgadmin/
        │   ├── Chart.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       └── pvc.yaml
        └── postgres/
            ├── Chart.yaml
            ├── values-prod.yaml.example
            └── templates/
                ├── statefulset.yaml
                ├── service.yaml
                ├── secret.yaml
                └── pvc.yaml

## Секреты

Никогда не коммитить в git:

| Файл | Содержимое |
|------|------------|
| ansible/vault.yml | Telegram токены, разрешённые IP-адреса |
| ansible/inventory.ini | Реальные IP-адреса серверов |
| terraform/terraform.tfvars | API токен Hetzner Cloud |
| terraform/backend.tfvars | Access key и Secret key для S3 |
| helm/n8n/values-prod.yaml | Домен, продовая конфигурация |
| helm/pgadmin/values.yaml | Домен, учётные данные pgAdmin |
| helm/postgres/values.yaml | Имя базы, имя пользователя, пароль |

Используйте .example файлы как шаблоны.

## Предварительные требования

### 0. Управляющая нода (sre-main)

**Terraform:**

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform

**Ansible:**

    sudo apt update && sudo apt install -y ansible

**SSH-ключ:**

    ssh-keygen -t ed25519 -C "sre-vps" -f ~/.ssh/id_ed25519
    cat ~/.ssh/id_ed25519.pub

**Клонируйте репозиторий:**

    git clone https://github.com/Oni-Wan-Shinobi/sre-platform.git
    cd sre-platform

### 1. Hetzner Object Storage bucket (ручной шаг)

1. Перейдите на console.hetzner.cloud → ваш проект → Object Storage
2. Нажмите Create Bucket
3. Имя: sre-terraform-state, Локация: Falkenstein (fsn1), Видимость: Private
4. Перейдите в S3 Credentials → Generate Credentials
5. Сохраните Access Key и Secret Key — вставьте их в terraform/backend.tfvars

### 2. Telegram боты

Создайте два бота через @BotFather в Telegram:
- Бот 1: для алертов fail2ban о попытках брутфорса SSH
- Бот 2: для мониторинга активности сервера

Узнайте ваш Chat ID — отправьте боту любое сообщение и откройте:
https://api.telegram.org/botВАШ_ТОКЕН/getUpdates

Найдите "chat":{"id":XXXXXXX} в ответе.

### 3. Домен

Добавьте A-запись, указывающую на публичный IP sre-node-1.

## Деплой

### Шаг 1 — Terraform

    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    cp backend.tfvars.example backend.tfvars
    terraform init -backend-config=backend.tfvars
    terraform apply

### Шаг 2 — Ansible bootstrap

    cd ansible
    cp vault.yml.example vault.yml
    cp inventory.ini.example inventory.ini
    ansible-playbook -i inventory.ini playbook.yml

Устанавливает на все ноды: Docker, UFW, fail2ban, iptables-persistent, Telegram-бот fail2ban, Telegram-бот мониторинга активности.

### Шаг 3 — k3s кластер

    ansible-playbook -i inventory.ini k3s.yml

Устанавливает k3s master на sre-node-1, подключает sre-node-2 как worker.

### Шаг 4 — Helm + kubectl

    ansible-playbook -i inventory.ini helm.yml

Устанавливает Helm и kubectl на sre-main, получает kubeconfig с master-ноды.

### Шаг 5 — cert-manager + TLS

    ansible-playbook -i inventory.ini cert-manager.yml

Устанавливает cert-manager и создаёт Let's Encrypt ClusterIssuer.

### Шаг 6 — Деплой приложений

    cd helm/n8n
    cp values-prod.yaml.example values-prod.yaml
    cd ../pgadmin
    cp values-prod.yaml.example values.yaml
    cd ../postgres
    cp values-prod.yaml.example values.yaml
    cd ../../ansible
    ansible-playbook -i inventory.ini deploy-apps.yml

Деплой вручную через Helm:

    helm upgrade --install pgadmin ~/sre-platform/helm/pgadmin --namespace default
    helm upgrade --install postgres ~/sre-platform/helm/postgres --namespace default

## Безопасность

- **UFW**: открыты только порты 22, 80, 443, 6443, 8472; всё остальное заблокировано
- **fail2ban**: банит IP-адреса после многократных неудачных попыток подключения по SSH
- **fail2ban-telegram**: мгновенные Telegram-уведомления при каждом бане
- **server-activity-telegram**: периодические отчёты об активности сервера в Telegram
- **iptables-persistent**: правила файрвола сохраняются после перезагрузки
- **Terraform S3 backend**: state хранится удалённо в Hetzner Object Storage
- **Управление секретами**: все токены и ключи хранятся вне git в vault.yml / tfvars файлах

<div align="right"><a href="#russian">👆 Наверх</a> · <a href="#english">👆 English</a></div>
