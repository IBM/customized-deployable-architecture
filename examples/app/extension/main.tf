locals {

  vpc_type = "workload"
  application = file("appInit.sh")
  config = file("config.txt")

  decodeConfig = jsondecode("${local.config}")

  vpc = [ for vpc in local.decodeConfig["vpcs"] :
      vpc if vpc.prefix == local.vpc_type
  ][0]

  prefix = "land-zone-vsi-qs"
  subnet = join("-", [local.prefix, local.vpc_type, local.vpc.subnets.zone-1[0].name])

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
        name      = "ssh-port-22",
        direction = "inbound",
        source    = "0.0.0.0/0",
        tcp = {
            port_max = 22,
            port_min = 22
        }
      },
      {
        name      = "outbound-off",
        direction = "outbound",
        source    = "0.0.0.0/0"
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
}

data "ibm_is_ssh_key" "ssh-key" {
  name = "${local.prefix}-ssh-key"
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
  vpc_id                     = data.ibm_is_subnet.subnet.vpc
  prefix                     = "apache-webserver"
  machine_type               = "cx2-2x4"
  user_data                  = local.application
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [data.ibm_is_ssh_key.ssh-key.id]
}