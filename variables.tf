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

# ==================== Network Variables ====================

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-e"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "homework-network"
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
  default     = "public"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "192.168.10.0/24"
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
  default     = "private"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "192.168.20.0/24"
}

variable "nat_instance_ip" {
  description = "IP address for NAT instance"
  type        = string
  default     = "192.168.10.254"
}

# ==================== Object Storage Variables ====================

variable "bucket_name" {
  description = "Name of the Object Storage bucket"
  type        = string
  default     = "netology-homework-bucket"
}

variable "image_file_path" {
  description = "Local path to the image file for uploading to bucket"
  type        = string
  default     = "image.jpg"
}

variable "image_object_key" {
  description = "Object key for the image in bucket"
  type        = string
  default     = "image.jpg"
}

# ==================== Compute Variables ====================

variable "nat_instance_image_id" {
  description = "Image ID for NAT instance"
  type        = string
  default     = "fd80mrhj8fl2oe87o4e1"
}

variable "lamp_image_id" {
  description = "Image ID for LAMP stack VMs"
  type        = string
  default     = "fd827b91d99psvq5fjit"
}

variable "vm_image_id" {
  description = "Image ID for virtual machines"
  type        = string
  default     = "fd8b0l3eaavvdm9ohgvj"
}

variable "vm_platform_id" {
  description = "Platform ID for virtual machines"
  type        = string
  default     = "standard-v2"
}

# ==================== Resource Variables for Regular VMs ====================

variable "vm_cores" {
  description = "Number of CPU cores for regular virtual machines"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory size in GB for regular virtual machines"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Disk size in GB for regular virtual machines"
  type        = number
  default     = 10
}

# ==================== Resource Variables for NAT Instance ====================

variable "nat_instance_cores" {
  description = "Number of CPU cores for NAT instance"
  type        = number
  default     = 4
}

variable "nat_instance_memory" {
  description = "Memory size in GB for NAT instance"
  type        = number
  default     = 4
}

variable "nat_instance_disk_size" {
  description = "Disk size in GB for NAT instance"
  type        = number
  default     = 20
}

# ==================== Instance Group Variables ====================

variable "instance_group_name" {
  description = "Name of the instance group"
  type        = string
  default     = "lamp-instance-group"
}

variable "instance_group_size" {
  description = "Number of instances in the group"
  type        = number
  default     = 3
}

variable "instance_group_cores" {
  description = "Number of CPU cores for instances in group"
  type        = number
  default     = 2
}

variable "instance_group_memory" {
  description = "Memory size in GB for instances in group"
  type        = number
  default     = 2
}

variable "instance_group_disk_size" {
  description = "Disk size in GB for instances in group"
  type        = number
  default     = 10
}

variable "instance_group_disk_type" {
  description = "Disk type for instances in group"
  type        = string
  default     = "network-hdd"
}

# ==================== Load Balancer Variables ====================

variable "load_balancer_name" {
  description = "Name of the network load balancer"
  type        = string
  default     = "lamp-load-balancer"
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds"
  type        = number
  default     = 2
}

variable "health_check_timeout" {
  description = "Timeout for health check in seconds"
  type        = number
  default     = 1
}

variable "health_check_healthy_threshold" {
  description = "Number of successful checks before considering instance healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of failed checks before considering instance unhealthy"
  type        = number
  default     = 3
}

# ==================== Username Variable ====================

variable "vm_username" {
  description = "Username for SSH access to VMs"
  type        = string
  default     = "ubuntu"
}

# ==================== Disk Type Variables ====================

variable "nat_instance_disk_type" {
  description = "Disk type for NAT instance (network-hdd, network-ssd)"
  type        = string
  default     = "network-hdd"
}

variable "public_vm_disk_type" {
  description = "Disk type for public VM (network-hdd, network-ssd)"
  type        = string
  default     = "network-hdd"
}

variable "private_vm_disk_type" {
  description = "Disk type for private VM (network-hdd, network-ssd)"
  type        = string
  default     = "network-hdd"
}

# ==================== KMS Variables ====================

variable "kms_key_name" {
  description = "Name of the KMS key"
  type        = string
  default     = "bucket-encryption-key"
}

variable "kms_key_rotation_period" {
  description = "Rotation period for KMS key"
  type        = string
  default     = "8760h"
}

# ==================== Certificate Variables ====================

variable "certificate_id" {
  description = "ID of the certificate in Yandex Certificate Manager"
  type        = string
  default     = ""
}

# ==================== Static Site Variables ====================

variable "static_site_domain" {
  description = "Domain name for static site"
  type        = string
  default     = ""
}