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
