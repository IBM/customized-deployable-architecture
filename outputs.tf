##############################################################################
# Outputs
##############################################################################

output "customSecInfra" {
  value       = module.landing_zone
  description = "Custom secure infrastructure configuration"
}

output "prefix" {
  value       = var.prefix
  description = "prefix used in this infrastructure"
}
