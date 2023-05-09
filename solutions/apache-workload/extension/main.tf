locals {

  vpc_type = "workload"

  # Determine where the workspace is for the prerequisite deployment.  The location is the first part of the
  # pre-requisite workspace's id string.  The workspace id is not provided when running as a full stack so check for a null value.
  location = var.prerequisite_workspace_id != "" ? regex("^[a-z/-]+", var.prerequisite_workspace_id ) : ""
}

data "ibm_schematics_workspace" "schematics_workspace" {
  # only query the resource if a workspace id was given (extension)
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}

data "ibm_schematics_output" "schematics_output" {
  # only query the resource if a workspace id was given (extension)
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
  template_id  = data.ibm_schematics_workspace.schematics_workspace[0].runtime_data[0].id
}

locals {
  slz_output = var.prerequisite_workspace_id != "" ? jsondecode(data.ibm_schematics_output.schematics_output[0].output_json) : null
  # prefix will either come from the prerequisite's workspace (extension) or it will come from a variable (fullstack).
  prefix = var.prerequisite_workspace_id != "" ? local.slz_output[0].prefix.value : var.prefix
  subnet = join("-", ["${local.prefix}", local.vpc_type, "vsi-zone-1"])
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

data "ibm_is_floating_ip" "jump-box-fip" {
  name = "${local.prefix}-jump-box-1-fip"
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git?ref=v2.0.0"
  resource_group_id          = data.ibm_is_subnet.subnet.resource_group
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = []
  subnets                    = [{"name": local.subnet, "id": data.ibm_is_subnet.subnet.id, "zone":data.ibm_is_subnet.subnet.zone, "cidr": data.ibm_is_subnet.subnet.ipv4_cidr_block}]
  vpc_id                     = data.ibm_is_subnet.subnet.vpc
  prefix                     = "${local.prefix}-apache-webserver"
  machine_type               = "cx2-2x4"
  user_data                  = var.workLoadInitScript
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [data.ibm_is_ssh_key.ssh-key.id]
}

resource "null_resource" "execute_ansible" {
  depends_on = [module.slz_vsi]
    
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = data.ibm_is_floating_ip.jump-box-fip.address
    host         = module.slz_vsi.list[0].ipv4_address
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "15m"
  }

  provisioner "file" {
    source      = "${path.module}/playbook/install-apache.yml"
    destination = "/root/install-apache.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 150",
      "ansible-playbook --connection=local -i 'localhost,' /root/install-apache.yml",
    ]
  }
}