output "prefix" {
    value       = local.prefix
    description = "prefix used for the apache deployment"
}

output "subnet-id" {
    value = local.subnet_id
    description = "id of the target subnet where Apache VSI is deployed"
}

output "vpc-id" {
    value = local.vpc_id
    description = "id of the VPC where the Apache VSI is deployed"
}

output "ssh-key-id" {
    value = local.ssh_key_id
    description = "id of the public ssh key to configure the VSI with for ssh access"
}

output "fp_vsi_floating_ip_address" {
    value = local.fp_vsi_floating_ip_address
    description = "the floating IP address to be used as a Bastion host to access the Apache VSI"
}