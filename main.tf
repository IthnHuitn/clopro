terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# ==================== Provider Configuration ====================

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = var.service_account_key_file
  zone                     = var.zone
}

# ==================== Data Sources ====================

data "local_file" "ssh_public_key" {
  filename = var.public_key_path
}

# ==================== Network Resources ====================

# Создание VPC
resource "yandex_vpc_network" "network" {
  name = var.vpc_name
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = var.public_subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
  name           = var.private_subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private_route.id
}

# Таблица маршрутизации для приватной подсети
resource "yandex_vpc_route_table" "private_route" {
  name       = "${var.private_subnet_name}-route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_instance_ip
  }
}

# ==================== Compute Resources ====================

# NAT-инстанс
resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance"
  hostname    = "nat-instance"
  platform_id = var.vm_platform_id
  zone        = var.zone

  resources {
    cores  = var.nat_instance_cores      
    memory = var.nat_instance_memory     
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_instance_image_id
      size     = var.nat_instance_disk_size  
      type     = var.nat_instance_disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    ip_address         = var.nat_instance_ip
    nat                = true 
    security_group_ids = []
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
  }

    connection {
      type        = "ssh"
      user        = var.vm_username
      private_key = file(replace(var.public_key_path, ".pub", ""))
      host        = self.network_interface[0].nat_ip_address
    }
  }

# Публичная виртуальная машина
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  hostname    = "public-vm"
  platform_id = var.vm_platform_id
  zone        = var.zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = var.vm_disk_size
      type     = var.public_vm_disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = []
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
  }

  depends_on = [yandex_compute_instance.nat_instance]
}

# Приватная виртуальная машина
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  hostname    = "private-vm"
  platform_id = var.vm_platform_id
  zone        = var.zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = var.vm_disk_size
      type     = var.private_vm_disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    security_group_ids = []
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
  }

  depends_on = [
    yandex_vpc_route_table.private_route,
    yandex_compute_instance.nat_instance
  ]
}
