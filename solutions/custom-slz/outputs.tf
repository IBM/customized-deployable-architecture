##############################################################################
# Outputs
##############################################################################

output "prefix" {
  value       = var.prefix
  description = "Prefix used to name resources is this deployment"
}

output "schematics_workspace_id" {
  description = "ID of the IBM Cloud Schematics workspace. Returns null if not ran in Schematics"
  value       = var.IC_SCHEMATICS_WORKSPACE_ID
}

output "vpc_data" {
  description = "This is the entire vpc data object for all of the VPCs created.  Includes all attributes of the VPCs"
  value = module.landing_zone.vpc_data
}

output "workload_vpc_id" {
  description = "The workload vpc id"
  value = [for vpc in module.landing_zone.vpc_data : vpc.vpc_id if vpc.vpc_name == join("-", [var.prefix, "workload", "vpc"])][0]
}
output "workload_vpc_name" {
  description = "The workload vpc name"
  value = join("-", [var.prefix, "workload", "vpc"])
}

output "subnet_data" {
  description = "All of the subnet data across the vpcs created"
  value = module.landing_zone.subnet_data
}

output "workload_subnet_id" {
  description = "workload subnet id"
  value = [for subnet in module.landing_zone.subnet_data : subnet.id if subnet.name == join("-", [var.prefix, "workload", "vsi-zone-1"])][0]
}
output "workload_subnet_name" {
  description = "workload subnet name"
  value = join("-", [var.prefix, "workload", "vsi-zone-1"])
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
  value = [for ssh_key in module.landing_zone.ssh_key_data : ssh_key.id if ssh_key.name == "ssh-key"][0]
}
output "ssh_key_name" {
  description = "ssh key name"
  value = "ssh-key"
}

output "fip_vsi" {
  description = "A list of VSI with name, id, zone, and primary ipv4 address, VPC Name, and floating IP. This list only contains instances with a floating IP attached."
  value       = module.landing_zone.fip_vsi
}

output "workload_vsi_fip" {
  description = "Floating point ip address of VSI within the workload VPC used as a Bastion/jumpbox host"
  value = [for fp in module.landing_zone.fip_vsi : fp.floating_ip if fp.name == join("-", [var.prefix, "jump-box-001"])][0]
}
output "workload_vsi_name" {
  description = "VSI hostname of the Bastion/jumpbox host that has an associated floating ip address"
  value = join("-", [var.prefix, "jump-box-001"])
}