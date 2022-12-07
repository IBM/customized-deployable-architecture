locals {

  vpc_type = "workload"

  #appInstallScript = file("${var.appInstallScript}")
  #customSecInfra = file("${var.customSecInfra}")

  #decodedInfrasctructure = jsondecode("${local.customSecInfra}")
  #vpc = [ for vpc in local.decodedInfrasctructure["vpcs"] :
  #    vpc if vpc.prefix == local.vpc_type
  #][0]

  subnet = join("-", [var.prefix, local.vpc_type, "vsi-zone-1"])
}

data "ibm_is_subnet" "subnet" {
  name = local.subnet
}

data "ibm_is_ssh_key" "ssh-key" {
  name = "${var.prefix}-ssh-key"
}

data "ibm_is_image" "image" {
  name = var.image
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git"
  resource_group_id          = data.ibm_is_subnet.subnet.resource_group
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = []
  subnets                    = [{"name": local.subnet, "id": data.ibm_is_subnet.subnet.id, "zone":data.ibm_is_subnet.subnet.zone, "cidr": data.ibm_is_subnet.subnet.ipv4_cidr_block}]
  vpc_id                     = data.ibm_is_subnet.subnet.vpc
  prefix                     = "apache-webserver"
  machine_type               = "cx2-2x4"
  user_data                  = var.appInstallScript
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [data.ibm_is_ssh_key.ssh-key.id]
}