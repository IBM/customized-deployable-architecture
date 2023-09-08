##############################################################################
# Landing Zone VSI Pattern
##############################################################################

module "landing_zone" {
  source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//patterns/vsi?archive=tgz&flavor=standard&kind=terraform&name=deploy-arch-ibm-slz-vsi&version=v4.4.7"
  prefix           = var.prefix
  #
  #  need us-south for ys1 - this is the only difference between release for prod env
  #
  region           = "us-south"
  ibmcloud_api_key = var.ibmcloud_api_key
  ssh_public_key   = var.ssh_key
  override         = true
}
