locals {

  vpc_type = "workload"

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

data "ibm_floating_ip" "jump-box-fip" {
  name = "$(var.prefix}-jump-box-1-fip"
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git?ref=v1.1.5"
  resource_group_id          = data.ibm_is_subnet.subnet.resource_group
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = []
  subnets                    = [{"name": local.subnet, "id": data.ibm_is_subnet.subnet.id, "zone":data.ibm_is_subnet.subnet.zone, "cidr": data.ibm_is_subnet.subnet.ipv4_cidr_block}]
  vpc_id                     = data.ibm_is_subnet.subnet.vpc
  prefix                     = "${var.prefix}-apache-webserver"
  machine_type               = "cx2-2x4"
  user_data                  = var.workLoadInitScript
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [data.ibm_is_ssh_key.ssh-key.id]
}

resource "null_resource" "execute_ansible" {
  dependepends_on = [module.slz_vsi]
    
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = data.ibm_floating_ip.jump-box-fip.address
    host         = module.slz_vsi.list[0].ipv4_address
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "15m"
  }

  provisioner "file" {
    source      = "${path.module}/playbooks/install-apache.yml"
    destination = "install-apache.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-playbook --connection=local -i 'localhost,' install-apache.yml",
    ]
  }
}