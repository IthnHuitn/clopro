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
  default     = "ru-central1-a"
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

# ==================== Compute Variables ====================

variable "nat_instance_image_id" {
  description = "Image ID for NAT instance"
  type        = string
  default     = "fd80mrhj8fl2oe87o4e1"
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