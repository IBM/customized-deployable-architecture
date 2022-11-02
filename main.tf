##############################################################################
# Landing Zone VSI Pattern
##############################################################################

module "landing_zone" {
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/vsi"
  prefix           = var.prefix
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  ssh_public_key   = var.ssh_key
  override         = true
}

locals {
  subnet = "land-zone-vsi-qs-workload-vsi-zone-1"
}

data "ibm_is_subnet" "subnet" {
  name = local.subnet
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git"
  resource_group_id          = data.ibm_is_subnet.subnet.resource_group
  image_id                   = "r010-2194ac54-23fe-486d-b652-15ac42a3982c"
  create_security_group      = false
  security_group             = null
  tags                       = []
  subnets                    = [{"name": local.subnet, "id": data.ibm_is_subnet.subnet.id, "zone":data.ibm_is_subnet.subnet.zone, "cidr": data.ibm_is_subnet.subnet.ipv4_cidr_block}]
  vpc_id                     =  data.ibm_is_subnet.subnet.vpc
  prefix                     = var.prefix
  machine_type               = "cx2-2x4"
  user_data                  = null
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = []
}
