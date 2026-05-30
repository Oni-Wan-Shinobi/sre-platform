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
- **Monitoring**: Prometheus + Grafana + Alertmanager + node-exporter + kube-state-metrics
- **Logging**: Loki + Alloy
- **Alerting**: Alertmanager + Telegram notifications
- **Bots**: Telegram bots for SSH brute-force alerts and server activity
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
| 9100 | TCP | node-exporter (internal only: 10.0.1.0/24, 10.42.0.0/16) |

## Repository Structure

    sre-platform/
    ├── RUNBOOKS.md
    ├── POSTMORTEM_TEMPLATE.md
    ├── .github/
    │   └── workflows/
    │       ├── deploy.yml
    │       ├── exporter.yml
    │       └── terraform.yml
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── backend.tfvars.example
    │   └── terraform.tfvars.example
    ├── ansible/
    │   ├── roles/
    │   │   ├── common/
    │   │   │   └── tasks/
    │   │   │       └── main.yml
    │   │   ├── fail2ban_telegram/
    │   │   │   └── tasks/
    │   │   │       └── main.yml
    │   │   └── server_activity/
    │   │       └── tasks/
    │   │           └── main.yml
    │   ├── inventory.ini.example
    │   ├── playbook.yml
    │   ├── k3s.yml
    │   ├── helm.yml
    │   ├── cert-manager.yml
    │   ├── deploy-apps.yml
    │   └── vault.yml.example
    ├── exporter/
    │   ├── Dockerfile
    │   ├── exporter.py
    │   ├── test_exporter.py
    │   ├── requirements.txt
    │   └── .flake8
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
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       └── pvc.yaml
        ├── postgres/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── statefulset.yaml
        │       ├── service.yaml
        │       ├── secret.yaml
        │       └── pvc.yaml
        ├── n8n-exporter/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── servicemonitor.yaml
        │       ├── secret.yaml
        │       └── _helpers.tpl
        ├── monitoring/
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       └── slo-rules.yaml
        └── loki/
            ├── values.yaml
            ├── values-prod.yaml.example
            └── alloy-values.yaml

## Secrets

Never commit to git:

| File | Contains |
|------|----------|
| ansible/vault.yml | Telegram tokens, whitelisted IPs |
| ansible/inventory.ini | Real server IP addresses |
| terraform/terraform.tfvars | Hetzner Cloud API token, SSH public key |
| terraform/backend.tfvars | S3 access key and secret key |
| helm/n8n/values-prod.yaml | Domain, production configuration |
| helm/pgadmin/values-prod.yaml | Domain, pgAdmin credentials |
| helm/postgres/values-prod.yaml | Database name, username, password |
| helm/monitoring/values-prod.yaml | Grafana password, Telegram alerts config |
| helm/loki/values-prod.yaml | Loki S3 access key and secret key |

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

Create three bots via @BotFather in Telegram:
- Bot 1: for fail2ban SSH brute-force alerts
- Bot 2: for server activity monitoring
- Bot 3: for Alertmanager infrastructure alerts (@sre_platform_alerts_bot)

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

### Step 6 — Monitoring stack

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    cp helm/monitoring/values-prod.yaml.example helm/monitoring/values-prod.yaml
    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace \
      --values helm/monitoring/values.yaml \
      --values helm/monitoring/values-prod.yaml

    kubectl apply -f helm/monitoring/templates/slo-rules.yaml

### Step 7 — Deploy applications

    cd helm/n8n
    cp values-prod.yaml.example values-prod.yaml
    cd ../pgadmin
    cp values-prod.yaml.example values-prod.yaml
    cd ../postgres
    cp values-prod.yaml.example values-prod.yaml
    cd ../../ansible
    ansible-playbook -i inventory.ini deploy-apps.yml

Manual Helm deploys:

    helm upgrade --install n8n ~/sre-platform/helm/n8n --namespace default --values helm/n8n/values.yaml --values helm/n8n/values-prod.yaml
    helm upgrade --install pgadmin ~/sre-platform/helm/pgadmin --namespace default --values helm/pgadmin/values.yaml --values helm/pgadmin/values-prod.yaml
    helm upgrade --install postgres ~/sre-platform/helm/postgres --namespace default --values helm/postgres/values.yaml --values helm/postgres/values-prod.yaml

### Step 8 — Logging stack (Loki + Alloy)

Loki runs in **SingleBinary** mode — one pod handles both reads and writes.
This is suitable for single-node or small clusters. Scale vertically by increasing pod resources.

> **Note:** Cache is disabled by default (`chunksCache.enabled: false`, `resultsCache.enabled: false`).
> Enable it in `helm/loki/values.yaml` if your server has enough memory (recommended: 1GB+ free).

    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    cp helm/loki/values-prod.yaml.example helm/loki/values-prod.yaml
    # Fill in your S3 credentials in values-prod.yaml
    helm upgrade --install loki grafana/loki \
      --namespace monitoring \
      --values helm/loki/values.yaml \
      --values helm/loki/values-prod.yaml

    helm upgrade --install alloy grafana/alloy \
      --namespace monitoring \
      --values helm/loki/alloy-values.yaml

Connect Loki to Grafana: Connections → Data sources → Add → Loki → URL:

    http://loki-gateway.monitoring.svc.cluster.local


### Step 9 — HTTP to HTTPS redirect (Traefik)

    kubectl apply -f helm/traefik-redirect.yaml

Forces all HTTP traffic to redirect to HTTPS with a 301 permanent redirect.


### Step 10 — CI/CD (GitHub Actions)

Set up a self-hosted runner on sre-main:

    mkdir -p ~/actions-runner && cd ~/actions-runner
    curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz
    tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz
    ./config.sh --url https://github.com/YOUR_USERNAME/sre-platform --token YOUR_TOKEN
    ./svc.sh install github-runner
    ./svc.sh start

Copy kubeconfig to runner user:

    mkdir -p /home/github-runner/.kube
    cp /root/.kube/config /home/github-runner/.kube/config
    chown -R github-runner:github-runner /home/github-runner/.kube
    chmod 600 /home/github-runner/.kube/config

Add the following GitHub Secrets in repository Settings → Secrets and variables → Actions:

| Secret | Contains |
|--------|----------|
| N8N_VALUES_PROD | Contents of helm/n8n/values-prod.yaml |
| PGADMIN_VALUES_PROD | Contents of helm/pgadmin/values-prod.yaml |
| POSTGRES_VALUES_PROD | Contents of helm/postgres/values-prod.yaml |
| N8N_API_KEY | n8n API key for Prometheus exporter |

Pipeline runs automatically on every push to main: lint → create values from secrets → deploy → verify.


## n8n Prometheus Exporter

Custom Prometheus exporter that collects n8n metrics via the n8n API.

**Metrics exposed:**
- `n8n_up` — n8n reachability
- `n8n_workflows_total` — total number of workflows
- `n8n_workflows_active` — number of active workflows
- `n8n_executions_total{status}` — executions by status (success/error/waiting)

**CI/CD pipeline** (`.github/workflows/exporter.yml`):

    lint (flake8) → test (pytest) → build multi-platform Docker → push to ghcr.io → deploy to k3s → rollback on failure

**Docker image:** `ghcr.io/oni-wan-shinobi/n8n-exporter:latest`

**Dockerfile:** multi-stage build (builder + minimal runtime), supports linux/amd64 and linux/arm64.

Add `N8N_API_KEY` to GitHub Secrets to enable the exporter pipeline.

## SLI / SLO / SLA

| Alert | SLO | Threshold | Runbook |
|-------|-----|-----------|---------|
| N8nSLOBreach | 99.5% success rate | error rate > 0.5% for 5m | [RB-01](RUNBOOKS.md#rb-01--n8n-is-down) |
| PostgresPodDown | pod always ready | not ready > 1m | [RB-02](RUNBOOKS.md#rb-02--postgresql-is-down) |
| NodeDown | node always up | unreachable > 2m | [RB-03](RUNBOOKS.md#rb-03--node-is-down) |
| HighCPUUsage | CPU < 85% | > 85% for 10m | [RB-04](RUNBOOKS.md#rb-04--high-cpu-usage) |
| HighMemoryUsage | Memory < 85% | > 85% for 10m | [RB-05](RUNBOOKS.md#rb-05--high-memory-usage) |
| DiskSpaceLow | Disk < 80% | > 80% for 5m | [RB-06](RUNBOOKS.md#rb-06--disk-space-low) |

## Runbooks & Incident Response

Operational playbooks for every alert: [RUNBOOKS.md](RUNBOOKS.md)

Post-mortem template for incident analysis: [POSTMORTEM_TEMPLATE.md](POSTMORTEM_TEMPLATE.md)

## Security

- **UFW**: only ports 22, 80, 443, 6443, 8472 open; all else denied
- **fail2ban**: bans IPs after repeated SSH failures
- **fail2ban-telegram**: real-time Telegram alerts on every ban event
- **server-activity-telegram**: periodic server activity reports to Telegram
- **iptables-persistent**: firewall rules survive reboots
- **Terraform S3 backend**: state stored remotely in Hetzner Object Storage
- **Secrets management**: all tokens and keys stored outside git in vault.yml / tfvars files
- **node-exporter**: port 9100 open only for internal networks (10.0.1.0/24, 10.42.0.0/16), managed via Ansible
- **SSH hardening**: password authentication disabled, pubkey only, MaxAuthTries 3, X11 forwarding disabled
- **CI/CD secrets**: production values stored in GitHub Secrets, never in git

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
- **Мониторинг**: Prometheus + Grafana + Alertmanager + node-exporter + kube-state-metrics
- **Логирование**: Loki + Alloy
- **Алертинг**: Alertmanager + Telegram-уведомления
- **Боты**: Telegram-боты для алертов о брутфорсе SSH и активности сервера
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
| 9100 | TCP | node-exporter (только внутри: 10.0.1.0/24, 10.42.0.0/16) |

## Структура репозитория

    sre-platform/
    ├── RUNBOOKS.md
    ├── POSTMORTEM_TEMPLATE.md
    ├── .github/
    │   └── workflows/
    │       ├── deploy.yml
    │       ├── exporter.yml
    │       └── terraform.yml
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── backend.tfvars.example
    │   └── terraform.tfvars.example
    ├── ansible/
    │   ├── roles/
    │   │   ├── common/
    │   │   │   └── tasks/
    │   │   │       └── main.yml
    │   │   ├── fail2ban_telegram/
    │   │   │   └── tasks/
    │   │   │       └── main.yml
    │   │   └── server_activity/
    │   │       └── tasks/
    │   │           └── main.yml
    │   ├── inventory.ini.example
    │   ├── playbook.yml
    │   ├── k3s.yml
    │   ├── helm.yml
    │   ├── cert-manager.yml
    │   ├── deploy-apps.yml
    │   └── vault.yml.example
    ├── exporter/
    │   ├── Dockerfile
    │   ├── exporter.py
    │   ├── test_exporter.py
    │   ├── requirements.txt
    │   └── .flake8
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
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── ingress.yaml
        │       └── pvc.yaml
        ├── postgres/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       ├── statefulset.yaml
        │       ├── service.yaml
        │       ├── secret.yaml
        │       └── pvc.yaml
        ├── n8n-exporter/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   └── templates/
        │       ├── deployment.yaml
        │       ├── service.yaml
        │       ├── servicemonitor.yaml
        │       ├── secret.yaml
        │       └── _helpers.tpl
        ├── monitoring/
        │   ├── values.yaml
        │   ├── values-prod.yaml.example
        │   └── templates/
        │       └── slo-rules.yaml
        └── loki/
            ├── values.yaml
            ├── values-prod.yaml.example
            └── alloy-values.yaml

## Секреты

Никогда не коммитить в git:

| Файл | Содержимое |
|------|------------|
| ansible/vault.yml | Telegram токены, разрешённые IP-адреса |
| ansible/inventory.ini | Реальные IP-адреса серверов |
| terraform/terraform.tfvars | API токен Hetzner Cloud, публичный SSH ключ |
| terraform/backend.tfvars | Access key и Secret key для S3 |
| helm/n8n/values-prod.yaml | Домен, продовая конфигурация |
| helm/pgadmin/values-prod.yaml | Домен, учётные данные pgAdmin |
| helm/postgres/values-prod.yaml | Имя базы, имя пользователя, пароль |
| helm/monitoring/values-prod.yaml | Пароль Grafana, конфиг Telegram алертов |
| helm/loki/values-prod.yaml | S3 access key и secret key для Loki |

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

Создайте три бота через @BotFather в Telegram:
- Бот 1: для алертов fail2ban о попытках брутфорса SSH
- Бот 2: для мониторинга активности сервера
- Бот 3: для алертов Alertmanager об инфраструктуре (@sre_platform_alerts_bot)

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

### Шаг 6 — Мониторинг

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    cp helm/monitoring/values-prod.yaml.example helm/monitoring/values-prod.yaml
    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace \
      --values helm/monitoring/values.yaml \
      --values helm/monitoring/values-prod.yaml

    kubectl apply -f helm/monitoring/templates/slo-rules.yaml

### Шаг 7 — Деплой приложений

    cd helm/n8n
    cp values-prod.yaml.example values-prod.yaml
    cd ../pgadmin
    cp values-prod.yaml.example values-prod.yaml
    cd ../postgres
    cp values-prod.yaml.example values-prod.yaml
    cd ../../ansible
    ansible-playbook -i inventory.ini deploy-apps.yml

Деплой вручную через Helm:

    helm upgrade --install n8n ~/sre-platform/helm/n8n --namespace default --values helm/n8n/values.yaml --values helm/n8n/values-prod.yaml
    helm upgrade --install pgadmin ~/sre-platform/helm/pgadmin --namespace default --values helm/pgadmin/values.yaml --values helm/pgadmin/values-prod.yaml
    helm upgrade --install postgres ~/sre-platform/helm/postgres --namespace default --values helm/postgres/values.yaml --values helm/postgres/values-prod.yaml

### Шаг 8 — Логирование (Loki + Alloy)

Loki работает в режиме **SingleBinary** — один под обрабатывает и чтение, и запись.
Подходит для одиночных нод и небольших кластеров. Масштабируется вертикально увеличением ресурсов пода.

> **Примечание:** Кэш отключён по умолчанию (`chunksCache.enabled: false`, `resultsCache.enabled: false`).
> Включите в `helm/loki/values.yaml` если сервер позволяет (рекомендуется: 1GB+ свободной памяти).

    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    cp helm/loki/values-prod.yaml.example helm/loki/values-prod.yaml
    # Заполните S3 ключи в values-prod.yaml
    helm upgrade --install loki grafana/loki \
      --namespace monitoring \
      --values helm/loki/values.yaml \
      --values helm/loki/values-prod.yaml

    helm upgrade --install alloy grafana/alloy \
      --namespace monitoring \
      --values helm/loki/alloy-values.yaml

Подключить Loki к Grafana: Connections → Data sources → Add → Loki → URL:

    http://loki-gateway.monitoring.svc.cluster.local


### Шаг 9 — Редирект HTTP → HTTPS (Traefik)

    kubectl apply -f helm/traefik-redirect.yaml

Принудительно перенаправляет весь HTTP трафик на HTTPS с кодом 301.


### Шаг 10 — CI/CD (GitHub Actions)

Установите self-hosted runner на sre-main:

    mkdir -p ~/actions-runner && cd ~/actions-runner
    curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz
    tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz
    ./config.sh --url https://github.com/ВАШ_USERNAME/sre-platform --token ВАШ_ТОКЕН
    ./svc.sh install github-runner
    ./svc.sh start

Скопируйте kubeconfig для пользователя runner:

    mkdir -p /home/github-runner/.kube
    cp /root/.kube/config /home/github-runner/.kube/config
    chown -R github-runner:github-runner /home/github-runner/.kube
    chmod 600 /home/github-runner/.kube/config

Добавьте GitHub Secrets в Settings → Secrets and variables → Actions:

| Секрет | Содержимое |
|--------|------------|
| N8N_VALUES_PROD | Содержимое helm/n8n/values-prod.yaml |
| PGADMIN_VALUES_PROD | Содержимое helm/pgadmin/values-prod.yaml |
| POSTGRES_VALUES_PROD | Содержимое helm/postgres/values-prod.yaml |
| N8N_API_KEY | API ключ n8n для Prometheus exporter |

Pipeline запускается автоматически при каждом push в main: lint → создание values из секретов → деплой → проверка.


## n8n Prometheus Exporter

Кастомный Prometheus exporter для сбора метрик n8n через API.

**Метрики:**
- `n8n_up` — доступность n8n
- `n8n_workflows_total` — общее количество workflows
- `n8n_workflows_active` — количество активных workflows
- `n8n_executions_total{status}` — выполнения по статусу (success/error/waiting)

**CI/CD pipeline** (`.github/workflows/exporter.yml`):

    lint (flake8) → test (pytest) → build multi-platform Docker → push to ghcr.io → deploy to k3s → rollback при ошибке

**Docker образ:** `ghcr.io/oni-wan-shinobi/n8n-exporter:latest`

**Dockerfile:** multi-stage сборка (builder + минимальный runtime), поддержка linux/amd64 и linux/arm64.

Добавьте `N8N_API_KEY` в GitHub Secrets для работы pipeline экспортера.

## SLI / SLO / SLA

| Алерт | SLO | Порог | Runbook |
|-------|-----|-------|---------|
| N8nSLOBreach | 99.5% успешных запросов | error rate > 0.5% за 5м | [RB-01](RUNBOOKS.md#rb-01--n8n-is-down) |
| PostgresPodDown | под всегда готов | not ready > 1м | [RB-02](RUNBOOKS.md#rb-02--postgresql-is-down) |
| NodeDown | нода всегда доступна | недоступна > 2м | [RB-03](RUNBOOKS.md#rb-03--node-is-down) |
| HighCPUUsage | CPU < 85% | > 85% за 10м | [RB-04](RUNBOOKS.md#rb-04--high-cpu-usage) |
| HighMemoryUsage | Memory < 85% | > 85% за 10м | [RB-05](RUNBOOKS.md#rb-05--high-memory-usage) |
| DiskSpaceLow | Disk < 80% | > 80% за 5м | [RB-06](RUNBOOKS.md#rb-06--disk-space-low) |

## Runbooks и реагирование на инциденты

Операционные плейбуки для каждого алерта: [RUNBOOKS.md](RUNBOOKS.md)

Шаблон post-mortem для разбора инцидентов: [POSTMORTEM_TEMPLATE.md](POSTMORTEM_TEMPLATE.md)

## Безопасность

- **UFW**: открыты только порты 22, 80, 443, 6443, 8472; всё остальное заблокировано
- **fail2ban**: банит IP-адреса после многократных неудачных попыток подключения по SSH
- **fail2ban-telegram**: мгновенные Telegram-уведомления при каждом бане
- **server-activity-telegram**: периодические отчёты об активности сервера в Telegram
- **iptables-persistent**: правила файрвола сохраняются после перезагрузки
- **Terraform S3 backend**: state хранится удалённо в Hetzner Object Storage
- **Управление секретами**: все токены и ключи хранятся вне git в vault.yml / tfvars файлах
- **node-exporter**: порт 9100 открыт только для внутренних сетей (10.0.1.0/24, 10.42.0.0/16), управляется через Ansible
- **SSH hardening**: аутентификация по паролю отключена, только pubkey, MaxAuthTries 3, X11 forwarding отключён
- **CI/CD секреты**: продовые values хранятся в GitHub Secrets, никогда не в git

<div align="right"><a href="#russian">👆 Наверх</a> · <a href="#english">👆 English</a></div>
