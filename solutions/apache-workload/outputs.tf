output "prefix" {
    value       = var.prefix
    description = "prefix used for the apache deployment"
}

output "resource_group_id" {
    value       = var.resource_group_id
    description = "id of the resource group containing the deployed resources"
}

output "subnet_id" {
    value = var.subnet_id
    description = "id of the target subnet where Apache VSI is deployed"
}

output "vpc_id" {
    value = var.vpc_id
    description = "id of the VPC where the Apache VSI is deployed"
}

output "ssh_key_id" {
    value = var.ssh_key_id
    description = "id of the public ssh key to configure the VSI with for ssh access"
}

output "fp_vsi_floating_ip_address" {
    value = var.fp_vsi_floating_ip_address
    description = "the floating IP address to be used as a Bastion host to access the Apache VSI"
}

output "webserver_ip_address" {
    value = module.slz_vsi.list[0].ipv4_address
    description = "the IP address of the deployed server where Apache will be installed"
}

output "ssh_private_key" {
    value = var.ssh_private_key
    description = "the ssh private key value that is paired with the public ssh key provided"
    sensitive = true
}