##############################################################################
# Outputs
##############################################################################

output "prefix" {
  value       = var.prefix
  description = "Prefix used to name resources is this deployment"
}

output "vpc_data" {
  description = "This is the entire vpc data object for all of the VPCs created.  Includes all attributes of the VPCs"
  value = module.landing_zone.vpc_data
}

output "region" {
  description = "The IBM Cloud region where resources were deployed"
  value = var.region
}

output "workload_vpc_id" {
  description = "The workload vpc id"
  value = module.landing_zone.vpc_data[0].vpc_id
}
output "workload_vpc_name" {
  description = "The workload vpc name"
  value = module.landing_zone.vpc_data[0].vpc_name
}

output "subnet_data" {
  description = "All of the subnet data across the vpcs created"
  value = module.landing_zone.subnet_data
}

output "workload_subnet_id" {
  description = "workload subnet id"
  value = module.landing_zone.subnet_data[0].id
}
output "workload_subnet_name" {
  description = "workload subnet name"
  value = module.landing_zone.subnet_data[0].name
}

output "resource_group_data" {
  description = "All of the resource group data"
  value = module.landing_zone.resource_group_data
}
output "resource_group_id" {
  description = "Resource group id used for deployed resources"
  value = values(module.landing_zone.resource_group_data)[0]
}
output "resource_group_name" {
  description = "Resource group name used for deployed resources"
  value = keys(module.landing_zone.resource_group_data)[0]
}

output "ssh_key_data" {
  description = "List of SSH key data"
  value       = module.landing_zone.ssh_key_data
}

output "ssh_key_id" {
  description = "ssh key id"
  value = module.landing_zone.ssh_key_data[0].id
}
output "ssh_key_name" {
  description = "ssh key name"
  value = module.landing_zone.ssh_key_data[0].name
}

output "fip_vsi" {
  description = "A list of VSI with name, id, zone, and primary ipv4 address, VPC Name, and floating IP. This list only contains instances with a floating IP attached."
  value       = module.landing_zone.fip_vsi
}

output "workload_vsi_fip" {
  description = "Floating point ip address of VSI within the workload VPC used as a Bastion/jumpbox host"
  value = module.landing_zone.fip_vsi[0].floating_ip
}
output "workload_vsi_name" {
  description = "VSI hostname of the Bastion/jumpbox host that has an associated floating ip address"
  value = module.landing_zone.fip_vsi[0].name
}