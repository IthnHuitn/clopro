# ==================== Network Outputs ====================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = yandex_vpc_network.network.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = yandex_vpc_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = yandex_vpc_subnet.private.id
}

output "route_table_id" {
  description = "ID of the route table"
  value       = yandex_vpc_route_table.private_route.id
}

# ==================== Object Storage Outputs ====================

output "bucket_name" {
  description = "Name of the Object Storage bucket"
  value       = var.bucket_name
}

output "image_url" {
  description = "URL of the uploaded image"
  value       = "https://${var.bucket_name}.website.yandexcloud.net/${var.image_object_key}"
}

# ==================== Instance Outputs ====================

output "nat_instance_internal_ip" {
  description = "Internal IP of NAT instance"
  value       = yandex_compute_instance.nat_instance.network_interface[0].ip_address
}

output "nat_instance_external_ip" {
  description = "External IP of NAT instance"
  value       = yandex_compute_instance.nat_instance.network_interface[0].nat_ip_address
}

output "public_vm_external_ip" {
  description = "External IP of public VM"
  value       = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
}

output "public_vm_internal_ip" {
  description = "Internal IP of public VM"
  value       = yandex_compute_instance.public_vm.network_interface[0].ip_address
}

output "private_vm_internal_ip" {
  description = "Internal IP of private VM"
  value       = yandex_compute_instance.private_vm.network_interface[0].ip_address
}

# ==================== Instance Group Outputs ====================

output "instance_group_id" {
  description = "ID of the instance group"
  value       = yandex_compute_instance_group.lamp_group.id
}

output "instance_group_instances" {
  description = "List of instances in the group"
  value       = yandex_compute_instance_group.lamp_group.instances
}

# ==================== Network Load Balancer Outputs ====================

output "load_balancer_ip" {
  description = "IP address of the network load balancer"
  value = one(
    [for listener in yandex_lb_network_load_balancer.lamp_lb.listener :
      one([for addr in listener.external_address_spec : addr.address])
    ]
  )
}

output "load_balancer_id" {
  description = "ID of the network load balancer"
  value       = yandex_lb_network_load_balancer.lamp_lb.id
}

output "target_group_id" {
  description = "ID of the target group"
  value       = yandex_lb_target_group.lamp_target_group.id
}

# ==================== Application Load Balancer Outputs ====================

output "alb_ip" {
  description = "IP address of the Application Load Balancer"
  value = one([
    for listener in yandex_alb_load_balancer.lamp_alb.listener :
    one([
      for endpoint in listener.endpoint :
      one([
        for address in endpoint.address :
        address.external_ipv4_address[0].address
      ])
    ])
  ])
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = yandex_alb_load_balancer.lamp_alb.id
}

output "alb_backend_group_id" {
  description = "ID of the ALB backend group"
  value       = yandex_alb_backend_group.lamp_backend_group.id
}

output "alb_target_group_id" {
  description = "ID of the ALB target group"
  value       = yandex_alb_target_group.lamp_alb_target_group.id
}

# ==================== SSH Connection Commands ====================

output "ssh_connection_command_public" {
  description = "SSH connection command for public VM"
  value       = "ssh ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}"
}

output "ssh_connection_command_private" {
  description = "SSH connection command for private VM (via public VM)"
  value       = "ssh -J ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address} ${var.vm_username}@${yandex_compute_instance.private_vm.network_interface[0].ip_address}"
}

output "ssh_connection_command_nat" {
  description = "SSH connection command for NAT instance"
  value       = "ssh ${var.vm_username}@${yandex_compute_instance.nat_instance.network_interface[0].nat_ip_address}"
}

# ==================== Test URLs ====================

output "test_load_balancer_url" {
  description = "URL to test the network load balancer"
  value = "http://${
    coalesce(
      one([
        for listener in yandex_lb_network_load_balancer.lamp_lb.listener :
        one([
          for address_spec in listener.external_address_spec :
          address_spec.address
        ])
      ]),
      "pending"
    )
  }/"
}

output "test_alb_url" {
  description = "URL to test the Application Load Balancer"
  value = "http://${
    coalesce(
      one([
        for listener in yandex_alb_load_balancer.lamp_alb.listener :
        one([
          for endpoint in listener.endpoint :
          one([
            for address in endpoint.address :
            address.external_ipv4_address[0].address
          ])
        ])
      ]),
      "pending"
    )
  }/"
}