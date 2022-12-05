module "landing-zone" {
    source           = "../.."
    prefix           = var.prefix
    ibmcloud_api_key = var.ibmcloud_api_key
    ssh_public_key   = var.ssh_key
}

module "apache" {
    source = "../../extension"
    config = module.landing-zone.config
}