locals {
  region = "eu-de"
}

module "customSecureInfra" {
  # source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//patterns/vsi?archive=tgz&catalogID=7df1e4ca-d54c-4fd0-82ce-3d13247308cd&flavor=standard&kind=terraform&name=slz-vpc-with-vsis&version=1.10.3"
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/vsi?ref=v1.10.3"
  prefix           = var.prefix
  region           = local.region
  ibmcloud_api_key = var.ibmcloud_api_key
  ssh_public_key   = var.ssh_key
  override         = true
}


module "appExtension" {
    source           = "git::https://github.com/IBM/customized-deployable-architecture//examples/app/extension"
    ibmcloud_api_key = var.ibmcloud_api_key
    region           = local.region
    prefix           = module.customSecureInfra.prefix
}