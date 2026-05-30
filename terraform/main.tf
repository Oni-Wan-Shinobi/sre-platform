terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
backend "s3" {
    bucket                      = "sre-terraform-state"
    key                         = "terraform.tfstate"
    region                      = "fsn1"
    endpoints = {
      s3 = "https://fsn1.your-objectstorage.com"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style            = true
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "vps" {
  name       = "sre-vps"
  public_key = var.ssh_public_key
}


# Сеть (аналог VPC в AWS)
resource "hcloud_network" "main" {
  name     = "sre-network"
  ip_range = "10.0.0.0/16"
}

# Подсеть
resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Firewall (аналог Security Groups в AWS)
resource "hcloud_firewall" "main" {
  name = "sre-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "8472"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Сервер (аналог EC2 в AWS)
resource "hcloud_server" "main" {
  name        = "sre-node-1"
  image       = "ubuntu-22.04"
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = ["hetzner", hcloud_ssh_key.vps.name]

  network {
    network_id = hcloud_network.main.id
    ip         = "10.0.1.10"
  }

  firewall_ids = [hcloud_firewall.main.id]
}

# Сервер 2 (worker node)
resource "hcloud_server" "node2" {
  name        = "sre-node-2"
  image       = "ubuntu-22.04"
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = ["hetzner", hcloud_ssh_key.vps.name]

  network {
    network_id = hcloud_network.main.id
    ip         = "10.0.1.11"
  }

  firewall_ids = [hcloud_firewall.main.id]
}

