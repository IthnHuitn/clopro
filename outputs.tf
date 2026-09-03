# ==================== Network Outputs ====================

output "vpc_id" {
  description = "ID of the VPC"
  value       = yandex_vpc_network.network.id
}

output "public_subnets" {
  description = "Public subnets"
  value = {
    "zone_a" = yandex_vpc_subnet.public_a.id
    "zone_b" = yandex_vpc_subnet.public_b.id
    "zone_d" = yandex_vpc_subnet.public_d.id
  }
}

output "private_subnets" {
  description = "Private subnets"
  value = {
    "zone_a" = yandex_vpc_subnet.private_a.id
    "zone_b" = yandex_vpc_subnet.private_b.id
  }
}

# ==================== MySQL Cluster Outputs ====================

output "mysql_cluster_id" {
  description = "ID of the MySQL cluster"
  value       = yandex_mdb_mysql_cluster.mysql_cluster.id
}

output "mysql_cluster_hosts" {
  description = "MySQL cluster hosts"
  value       = yandex_mdb_mysql_cluster.mysql_cluster.host
}

output "mysql_db_name" {
  description = "MySQL database name"
  value       = yandex_mdb_mysql_database.netology_db.name
}

output "mysql_user" {
  description = "MySQL user name"
  value       = yandex_mdb_mysql_user.netology_user.name
}

# ==================== Kubernetes Cluster Outputs ====================

output "k8s_cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = yandex_kubernetes_cluster.k8s_cluster.id
}

output "k8s_node_groups" {
  description = "Kubernetes node groups"
  value = {
    "zone_a" = yandex_kubernetes_node_group.k8s_node_group_a.id
    "zone_b" = yandex_kubernetes_node_group.k8s_node_group_b.id
    "zone_d" = yandex_kubernetes_node_group.k8s_node_group_d.id
  }
}

output "external_v4_endpoint" {
  value = data.yandex_kubernetes_cluster.my_cluster.master[0].external_v4_endpoint
}

# ==================== KMS Outputs ====================

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = data.yandex_kms_symmetric_key.existing_key.id
}