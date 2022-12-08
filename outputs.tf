##############################################################################
# Outputs
##############################################################################

output "customSecInfra" {
  value       = module.landing_zone
  description = "Custom secure infrastructure configuration"
}

output "dummy" {
  value       = "dumdum"
  description = "just something"
}
