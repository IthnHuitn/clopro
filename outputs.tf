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