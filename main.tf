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
  zone                     = var.zone_a
}

# ==================== Data Sources ====================

data "local_file" "ssh_public_key" {
  filename = var.public_key_path
}

data "yandex_kms_symmetric_key" "existing_key" {
  name = var.kms_key_name
}

data "yandex_kubernetes_cluster" "my_cluster" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
}

# ==================== Network Resources ====================

resource "yandex_vpc_network" "network" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.40.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = var.zone_d
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.60.0/24"]
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_instance_ip
  }
}

# ==================== Security Group ====================

resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol          = "TCP"
    description       = "Health checks from load balancer"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Master-node communication"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol       = "ANY"
    description    = "Pod-pod and service-service communication"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.public_b.v4_cidr_blocks[0],
      yandex_vpc_subnet.public_d.v4_cidr_blocks[0]
    ]
    from_port = 0
    to_port   = 65535
  }

  ingress {
    protocol       = "ICMP"
    description    = "Debug ICMP packets"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 443
    to_port        = 6443
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

resource "yandex_iam_service_account" "k8s_sa" {
  name        = "k8s-service-account"
  description = "Service account for Kubernetes cluster"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_clusters_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_images_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_encrypter_decrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_logging_writer" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# ==================== KMS Resources ====================

resource "yandex_kms_symmetric_key_iam_member" "k8s_kms_member" {
  symmetric_key_id = data.yandex_kms_symmetric_key.existing_key.id
  role            = "kms.keys.encrypterDecrypter"
  member          = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# ==================== Logging Resources ====================

resource "yandex_logging_group" "k8s_logs" {
  name        = "k8s-cluster-logs"
  description = "Logs for Kubernetes cluster"
}

# ==================== MySQL Cluster ====================

resource "yandex_mdb_mysql_cluster" "mysql_cluster" {
  name        = var.mysql_cluster_name
  environment = var.mysql_environment
  network_id  = yandex_vpc_network.network.id
  version     = var.mysql_version
  
  resources {
    resource_preset_id = var.mysql_resource_preset_id
    disk_type_id       = var.mysql_disk_type_id
    disk_size          = var.mysql_disk_size
  }

  maintenance_window {
    type = "ANYTIME"
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  deletion_protection = true

  host {
    zone      = var.zone_a
    subnet_id = yandex_vpc_subnet.private_a.id
    assign_public_ip = true
  }

  host {
    zone      = var.zone_b
    subnet_id = yandex_vpc_subnet.private_b.id
    assign_public_ip = true
  }
}

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.mysql_db_name
}

resource "yandex_mdb_mysql_user" "netology_user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.mysql_user
  password   = var.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
}

# ==================== Kubernetes Cluster ====================

resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name       = var.k8s_cluster_name
  network_id = yandex_vpc_network.network.id
  
  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
  
  master {
    version = var.k8s_version
    
    master_location {
      zone      = var.zone_a
      subnet_id = yandex_vpc_subnet.public_a.id
    }
    
    master_location {
      zone      = var.zone_b
      subnet_id = yandex_vpc_subnet.public_b.id
    }
    
    master_location {
      zone      = var.zone_d
      subnet_id = yandex_vpc_subnet.public_d.id
    }

    public_ip = true

    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    
  #  external_v4_endpoint = true

    master_logging {
      enabled      = true
      log_group_id = yandex_logging_group.k8s_logs.id
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id
  
  kms_provider {
    key_id = data.yandex_kms_symmetric_key.existing_key.id
  }
  
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_clusters_agent,
    yandex_resourcemanager_folder_iam_member.k8s_vpc_public_admin,
    yandex_resourcemanager_folder_iam_member.k8s_images_puller,
    yandex_resourcemanager_folder_iam_member.k8s_encrypter_decrypter,
    yandex_kms_symmetric_key_iam_member.k8s_kms_member,
    yandex_logging_group.k8s_logs
  ]
}

# ==================== Kubernetes Node Groups ====================

resource "yandex_kubernetes_node_group" "k8s_node_group_a" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-a"
  
  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }

  instance_template {
    platform_id = "standard-v2"
    
    resources {
      cores  = var.k8s_node_cores
      memory = var.k8s_node_memory
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_node_disk_size
    }

    network_interface {
      subnet_ids         = [yandex_vpc_subnet.public_a.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    }

    metadata = {
      ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
    }
  }

  allocation_policy {
    location {
      zone = var.zone_a
    }
  }

  depends_on = [yandex_kubernetes_cluster.k8s_cluster]
}

resource "yandex_kubernetes_node_group" "k8s_node_group_b" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-b"
  
  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }

  instance_template {
    platform_id = "standard-v2"
    
    resources {
      cores  = var.k8s_node_cores
      memory = var.k8s_node_memory
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_node_disk_size
    }

    network_interface {
      subnet_ids         = [yandex_vpc_subnet.public_b.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    }

    metadata = {
      ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
    }
  }

  allocation_policy {
    location {
      zone = var.zone_b
    }
  }

  depends_on = [yandex_kubernetes_cluster.k8s_cluster]
}

resource "yandex_kubernetes_node_group" "k8s_node_group_d" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-d"
  
  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }

  instance_template {
    platform_id = "standard-v2"
    
    resources {
      cores  = var.k8s_node_cores
      memory = var.k8s_node_memory
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_node_disk_size
    }

    network_interface {
      subnet_ids         = [yandex_vpc_subnet.public_d.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    }

    metadata = {
      ssh-keys = "${var.vm_username}:${data.local_file.ssh_public_key.content}"
    }
  }

  allocation_policy {
    location {
      zone = var.zone_d
    }
  }

  depends_on = [yandex_kubernetes_cluster.k8s_cluster]
}