
# the image resource is always present and it is ok to query it.  query the image to obtain the 
# image id.
data "ibm_is_image" "image" {
  name = var.image
}

data "ibm_is_subnet" "by-subnet-id" {
  identifier = var.subnet_id
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git?ref=v4.6.0"
  resource_group_id          = var.resource_group_id
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = ["apache"]
  access_tags                = []
  subnets                    = [{"name": data.ibm_is_subnet.by-subnet-id.name, "id": var.subnet_id, "zone":data.ibm_is_subnet.by-subnet-id.zone, "cidr": data.ibm_is_subnet.by-subnet-id.ipv4_cidr_block}]
  vpc_id                     = var.vpc_id
  prefix                     = join("-", [var.prefix, "apache-webserver"])
  placement_group_id         = null
  machine_type               = "cx2-2x4"
  user_data                  = null
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [var.ssh_key_id]
}