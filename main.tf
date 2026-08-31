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

data "local_file" "image_file" {
  filename = var.image_file_path
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

# ==================== Security Group ====================

resource "yandex_vpc_security_group" "lamp_sg" {
  name        = "lamp-security-group"
  description = "Security group for LAMP instances and load balancer"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Traffic from load balancer"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Traffic from ALB"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ==================== IAM Resources ====================

# Создание сервисного аккаунта
resource "yandex_iam_service_account" "storage_sa" {
  name        = "storage-service-account"
  description = "Service account for Object Storage and Instance Group"
}

# Назначение роли редактора
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "storage_key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description        = "Static access key for Object Storage"
}

# ==================== KMS Resources ====================

# Создание ключа в KMS
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-encryption-key"
  description       = "Key for bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

# Привязка ключа к сервисному аккаунту
resource "yandex_kms_symmetric_key_iam_binding" "key_binding" {
  symmetric_key_id = yandex_kms_symmetric_key.bucket_key.id
  role            = "kms.keys.encrypterDecrypter"
  members         = ["serviceAccount:${yandex_iam_service_account.storage_sa.id}"]
}

# ==================== Object Storage Resources ====================

# Включение шифрования для существующего бакета через null_resource
resource "null_resource" "enable_bucket_encryption" {
  provisioner "local-exec" {
    command = <<-EOT
      export AWS_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.storage_key.access_key}"
      export AWS_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.storage_key.secret_key}"
      export AWS_ENDPOINT_URL="https://storage.yandexcloud.net"
      
      aws s3api put-bucket-encryption \
        --bucket ${var.bucket_name} \
        --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"aws:kms\",\"KMSMasterKeyID\":\"${yandex_kms_symmetric_key.bucket_key.id}\"}}]}" \
        --endpoint-url $AWS_ENDPOINT_URL
    EOT
  }

  depends_on = [
    yandex_kms_symmetric_key.bucket_key,
    yandex_kms_symmetric_key_iam_binding.key_binding,
    yandex_iam_service_account_static_access_key.storage_key
  ]
}

# Загрузка файла в существующий бакет
resource "yandex_storage_object" "image_object" {
  bucket       = var.bucket_name
  key          = var.image_object_key
  source       = var.image_file_path
  access_key   = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.storage_key.secret_key
  acl          = "public-read"
  content_type = "image/jpeg"

  depends_on = [null_resource.enable_bucket_encryption]
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
    security_group_ids = [yandex_vpc_security_group.lamp_sg.id]
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
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
    security_group_ids = [yandex_vpc_security_group.lamp_sg.id]
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
    security_group_ids = [yandex_vpc_security_group.lamp_sg.id]
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
  }

  depends_on = [
    yandex_vpc_route_table.private_route,
    yandex_compute_instance.nat_instance
  ]
}

# ==================== Instance Group Resources ====================

# Шаблон инстанса для группы
resource "yandex_compute_instance_group" "lamp_group" {
  name                = var.instance_group_name
  folder_id           = var.folder_id
  service_account_id  = yandex_iam_service_account.storage_sa.id
  deletion_protection = false

  instance_template {
    platform_id = var.vm_platform_id
    
    resources {
      cores  = var.instance_group_cores
      memory = var.instance_group_memory
    }

    boot_disk {
      initialize_params {
        image_id = var.lamp_image_id
        size     = var.instance_group_disk_size
        type     = var.instance_group_disk_type
      }
    }

    network_interface {
      subnet_ids         = [yandex_vpc_subnet.public.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.lamp_sg.id]
    }

    metadata = {
      ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
      user-data = <<-EOF
        #cloud-config
        write_files:
          - path: /var/www/html/index.html
            content: |
              <!DOCTYPE html>
              <html>
              <head>
                  <title>LAMP Server</title>
                  <style>
                  body {
                      font-family: Arial, sans-serif;
                      text-align: center;
                      padding: 20px;
                  }
                  img {
                      max-width: 800px;
                      width: 100%;
                      height: auto;
                  }
                  .hostname {
                      color: #007bff;
                      font-weight: bold;
                  }
              </style>
              </head>
              <body>
                  <h1>Welcome to LAMP Server</h1>
                  <p>"https://${var.bucket_name}.website.yandexcloud.net/${var.image_object_key}"<p>
                  <img src="https://${var.bucket_name}.website.yandexcloud.net/${var.image_object_key}" alt="Image from Object Storage">
              </body>
              </html>
        runcmd:
          - systemctl restart apache2
      EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = var.instance_group_size
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  health_check {
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    http_options {
      path = var.health_check_path
      port = var.health_check_port
    }
  }

  depends_on = [
    yandex_storage_object.image_object,
    yandex_resourcemanager_folder_iam_member.editor
  ]
}

# ==================== Network Load Balancer Resources ====================

# Создание целевой группы для сетевого балансировщика
resource "yandex_lb_target_group" "lamp_target_group" {
  name      = "lamp-target-group"
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance_group.lamp_group.instances
    content {
      subnet_id = yandex_vpc_subnet.public.id
      address   = target.value.network_interface[0].ip_address
    }
  }

  depends_on = [yandex_compute_instance_group.lamp_group]
}

# Сетевой балансировщик
resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = var.load_balancer_name

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp_target_group.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = var.health_check_port
        path = var.health_check_path
      }
      interval            = 2
      timeout             = 1
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }

  depends_on = [yandex_lb_target_group.lamp_target_group]
}

# ==================== Application Load Balancer Resources ====================

# Target Group для ALB
resource "yandex_alb_target_group" "lamp_alb_target_group" {
  name = "lamp-alb-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = yandex_compute_instance_group.lamp_group.instances[0].network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = yandex_compute_instance_group.lamp_group.instances[1].network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = yandex_compute_instance_group.lamp_group.instances[2].network_interface[0].ip_address
  }

  depends_on = [yandex_compute_instance_group.lamp_group]
}

# Backend Group для ALB
resource "yandex_alb_backend_group" "lamp_backend_group" {
  name = "lamp-backend-group"

  http_backend {
    name             = "lamp-http-backend"
    port             = 80
    target_group_ids = [yandex_alb_target_group.lamp_alb_target_group.id]
    
    load_balancing_config {
      mode = "ROUND_ROBIN"
    }

    healthcheck {
      timeout             = "1s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }

  depends_on = [yandex_alb_target_group.lamp_alb_target_group]
}

# HTTP Router для ALB
resource "yandex_alb_http_router" "lamp_router" {
  name = "lamp-router"
}

# Virtual Host для ALB
resource "yandex_alb_virtual_host" "lamp_virtual_host" {
  name           = "lamp-virtual-host"
  http_router_id = yandex_alb_http_router.lamp_router.id

  route {
    name = "lamp-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lamp_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "lamp_alb" {
  name               = "lamp-application-load-balancer"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.lamp_sg.id]

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lamp_router.id
      }
    }
  }

  depends_on = [
    yandex_compute_instance_group.lamp_group,
    yandex_alb_backend_group.lamp_backend_group,
    yandex_alb_http_router.lamp_router,
    yandex_alb_virtual_host.lamp_virtual_host
  ]
}