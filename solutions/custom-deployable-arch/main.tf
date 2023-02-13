##############################################################################
# Landing Zone VSI Pattern
##############################################################################

module "landing_zone" {
  #source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//patterns/vsi?archive=tgz&catalogID=7df1e4ca-d54c-4fd0-82ce-3d13247308cd&flavor=standard&kind=terraform&name=slz-vpc-with-vsis&version=v2.0.0"
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/vsi?ref=v2.0.0"
  prefix           = var.prefix
  region           = "us-east"
  ibmcloud_api_key = var.ibmcloud_api_key
  ssh_public_key   = var.ssh_key
  override         = true
}
