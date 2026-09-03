# ==================== Yandex Cloud Provider Variables ====================

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "service_account_key_file" {
  description = "Path to the service account key file"
  type        = string
}

# ==================== SSH Variables ====================

variable "public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
}

variable "vm_username" {
  description = "Username for SSH access to VMs"
  type        = string
  default     = "ubuntu"
}

# ==================== Network Variables ====================

variable "zone_a" {
  description = "Yandex Cloud availability zone A"
  type        = string
  default     = "ru-central1-a"
}

variable "zone_b" {
  description = "Yandex Cloud availability zone B"
  type        = string
  default     = "ru-central1-b"
}

variable "zone_d" {
  description = "Yandex Cloud availability zone D"
  type        = string
  default     = "ru-central1-d"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "homework-network"
}

variable "nat_instance_ip" {
  description = "IP address for NAT instance"
  type        = string
  default     = "192.168.10.254"
}

# ==================== KMS Variables ====================

variable "kms_key_name" {
  description = "Name of the existing KMS key"
  type        = string
  default     = "bucket-encryption-key"
}

# ==================== MySQL Cluster Variables ====================

variable "mysql_cluster_name" {
  description = "Name of the MySQL cluster"
  type        = string
  default     = "netology-mysql-cluster"
}

variable "mysql_resource_preset_id" {
  description = "Resource preset for MySQL hosts"
  type        = string
  default     = "b2.medium"
}

variable "mysql_disk_type_id" {
  description = "Disk type for MySQL"
  type        = string
  default     = "network-ssd"
}

variable "mysql_environment" {
  description = "MySQL cluster environment"
  type        = string
  default     = "PRESTABLE"
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0"
}

variable "mysql_disk_size" {
  description = "Disk size in GB for MySQL"
  type        = number
  default     = 20
}

variable "mysql_db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "netology_db"
}

variable "mysql_user" {
  description = "MySQL user name"
  type        = string
  default     = "netology_user"
}

variable "mysql_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
  default     = "SecurePassword123!"
}

# ==================== Kubernetes Cluster Variables ====================

variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "netology-k8s-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "k8s_node_cores" {
  description = "Number of CPU cores for Kubernetes nodes"
  type        = number
  default     = 2
}

variable "k8s_node_memory" {
  description = "Memory size in GB for Kubernetes nodes"
  type        = number
  default     = 4
}

variable "k8s_node_disk_size" {
  description = "Disk size in GB for Kubernetes nodes"
  type        = number
  default     = 50
}

variable "k8s_node_group_size" {
  description = "Initial number of nodes in Kubernetes cluster"
  type        = number
  default     = 1
}

variable "k8s_node_group_max_size" {
  description = "Maximum number of nodes in Kubernetes cluster"
  type        = number
  default     = 2
}

variable "k8s_node_group_min_size" {
  description = "Minimum number of nodes in Kubernetes cluster"
  type        = number
  default     = 1
}