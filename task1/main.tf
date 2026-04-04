terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }

  backend "s3" {
    # Використовуємо актуальний формат для S3-сумісних сховищ
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
    region                      = "us-east-1" # Заглушка, обов'язкова для S3 backend
    bucket                      = "datsko-bucket"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

# 1. Створення VPC
resource "digitalocean_vpc" "datsko_vpc" {
  name     = "datsko-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# 2. Налаштування Фаєрволу
resource "digitalocean_firewall" "datsko_fw" {
  name = "datsko-firewall"
  droplet_ids = [digitalocean_droplet.datsko_node.id]

  # Вхідні правила для вказаних портів
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  dynamic "inbound_rule" {
    for_each = ["80", "443", "8000", "8001", "8002", "8003"]
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0"]
    }
  }

  # Вихідні правила (усі порти)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# 3. Створення Віртуальної Машини (Droplet)
resource "digitalocean_droplet" "datsko_node" {
  name     = "datsko-node"
  size     = "s-4vcpu-8gb" # Системні вимоги для Minikube/K8s
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.datsko_vpc.id
  ssh_keys = [var.ssh_key_fingerprint]
}

# Оголошення змінних (щоб Terraform знав, що вони існують)
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint or Name of your SSH Key in DO"
  type        = string
}
