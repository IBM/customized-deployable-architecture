##############################################################################
# Outputs
##############################################################################

output "prefix" {
  value       = var.prefix
  description = "prefix used in this infrastructure"
}

output "schematics_workspace_id" {
  description = "ID of the IBM Cloud Schematics workspace. Returns null if not ran in Schematics"
  value       = var.IC_SCHEMATICS_WORKSPACE_ID
}

output "vpc_data" {
  description = "vpc data"
  value = module.landing_zone.vpc_data
}

output "subnet_data" {
  description = "subnet data"
  value = module.landing_zone.subnet_data
}

output "resource_group_data" {
  description = "resource group data"
  value = module.landing_zone.resource_group_data
}

output "ssh_key_data" {
  description = "List of SSH key data"
  value       = module.landing_zone.ssh_key_data
}

output "fip_vsi" {
  description = "A list of VSI with name, id, zone, and primary ipv4 address, VPC Name, and floating IP. This list only contains instances with a floating IP attached."
  value       = module.landing_zone.fip_vsi
}