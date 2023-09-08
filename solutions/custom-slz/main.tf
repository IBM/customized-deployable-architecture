##############################################################################
# Landing Zone VSI Pattern
##############################################################################

module "landing_zone" {
  #source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//patterns/vsi?archive=tgz&flavor=standard&kind=terraform&name=deploy-arch-ibm-slz-vsi&version=v4.4.7"
  source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source?archive=tgz&flavor=standard&installType=fullstack&kind=terraform&name=deploy-arch-ibm-slz-vsi&version=v4.4.7"
  # for certain testing purposes use the following source.
  #source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/vsi?ref=v4.7.0"
  prefix           = var.prefix
  region           = "us-south"
  ibmcloud_api_key = var.ibmcloud_api_key
  ssh_public_key   = var.ssh_key
  override         = true
}
