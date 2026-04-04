terraform {
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean" }
  }
  backend "s3" {
    endpoint                    = "fra1.digitaloceanspaces.com"
    region                      = "us-east-1" # Заглушка для S3-сумісного сховища
    bucket                      = "datsko-bucket"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "datsko_vpc" {
  name     = "datsko-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_firewall" "datsko_fw" {
  name = "datsko-firewall"
  droplet_ids = [digitalocean_droplet.datsko_node.id]

  inbound_rule {
    protocol   = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  
  # Правила для 80, 443, 8000-8003
  dynamic "inbound_rule" {
    for_each = ["80", "443", "8000", "8001", "8002", "8003"]
    content {
      protocol = "tcp"
      port_range = inbound_rule.value
      source_addresses = ["0.0.0.0/0"]
    }
  }

  outbound_rule {
    protocol   = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_droplet" "datsko_node" {
  name     = "datsko-node"
  size     = "s-4vcpu-8gb" # Відповідає вимогам Minikube
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.datsko_vpc.id
  ssh_keys = [var.ssh_key_fingerprint]
}
