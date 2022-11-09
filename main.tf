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

  security_group = {
    name = "httpd-sg",
    rules = [
      {
        name      = "httpd-port-80",
        direction = "inbound",
        source    = "0.0.0.0/0",
        tcp = {
            port_max = 80,
            port_min = 80
        }
      },
      { 
        name      = "httpd-port-443",
        direction = "inbound",
        source    = "0.0.0.0/0",
        tcp = {
            port_max = 443,
            port_min = 443
        }
      }
    ]
  }
}

data "ibm_is_subnet" "subnet" {
  name = local.subnet
  
  depends_on = [module.landing_zone]
}

data "ibm_is_ssh_key" "ssh-key" {
  name = "${var.prefix}-ssh-key"
  
  depends_on = [module.landing_zone]
}

data "ibm_is_image" "image" {
  name = var.image
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git"
  resource_group_id          = data.ibm_is_subnet.subnet.resource_group
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = local.security_group
  tags                       = []
  subnets                    = [{"name": local.subnet, "id": data.ibm_is_subnet.subnet.id, "zone":data.ibm_is_subnet.subnet.zone, "cidr": data.ibm_is_subnet.subnet.ipv4_cidr_block}]
  vpc_id                     =  data.ibm_is_subnet.subnet.vpc
  prefix                     = var.prefix
  machine_type               = "cx2-2x4"
  user_data                  = <<EOF
#!/bin/bash
sudo apt-get update

sudo apt-get --yes install apache2

EOF
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [data.ibm_is_ssh_key.ssh-key.id]
}
