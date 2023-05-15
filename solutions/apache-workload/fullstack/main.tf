module "custom_slz" {
    source = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/custom-slz?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=babyslz&kind=terraform&name=custom-deployable-arch&version=0.0.49"
    prefix           = var.prefix
    ssh_key          = var.ssh_key
    ibmcloud_api_key = var.ibmcloud_api_key
}

#
# this implementation is such that the apache workload module is deployed in the same apply operation as the the dependency layer - custom slz.  Therefore
# the information needed by the worload apply comes from direct outputs of the custom slz.
#

locals {
  # lets deploy the workload on the "workload" vpc in the base layer.
  vpc_type = "workload"

  vpc_name = join("-", [var.prefix, local.vpc_type, "vpc"])
  vpc_id = [for vpc in module.custom_slz.vpc_data : vpc.vpc_id if vpc.vpc_name == local.vpc_name][0]

  subnet_name = join("-", [var.prefix, local.vpc_type, "vsi-zone-1"])
  subnet_id = [for subnet in module.custom_slz.subnet_data : subnet.id if subnet.name == local.subnet_name][0]

  # rg_name = join("-", ["slz", local.vpc_type, "rg"])
  # resource_group_id = lookup(module.custom_slz.resource_group_data, local.rg_name, "")

  ssh_key_id = [for ssh_key in module.custom_slz.ssh_key_data : ssh_key.id if ssh_key.name == "ssh-key"][0]

  fp_vsi_name = join("-", [var.prefix, "jump-box-1"])
  fp_vsi_floating_ip_address = [for fp in module.custom_slz.fip_vsi : fp.floating_ip if fp.name == local.fp_vsi_name][0]
  #fp_vsi_ipv4_address = [for fp in module.custom_slz.fip_vsi : fp.ipv4_address if fp.name == local.fp_vsi_name][0]
}

# this is all debuggin 
output "vpc_id" {
  value = local.vpc_id
  description = "target vpc id"
}
output "subnet_id" {
  value = "${local.subnet_id}"
  description = "target subnet id"
}
# output "resource_group_id" {
#   value = local.resource_group_id}
#   description = "target rg id"
# }
output "ssh_key_id" {
  value = local.ssh_key_id
  description = "target ssh key id"
}
output "fp_vsi_floating_ip_address" {
  value = local.fp_vsi_floating_ip_address
  description = "target fp_vsi_floating_ip_address"
}
# output "fp_vsi_ipv4_address" {
#   value = local.fp_vsi_ipv4_address
#   description = "target fp_vsi_ipv4_address"
# }

data "ibm_resource_group" "group" {
  name = "Default"
}

module "custom_apache" {
  #source                    = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/custom-apache/workload-only/ansible?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=standard&kind=terraform&name=custom-apache&version=0.0.28"
  source  = "../extension"
  ibmcloud_api_key          = var.ibmcloud_api_key
  prerequisite_workspace_id = var.prerequisite_workspace_id
  ssh_private_key           = var.ssh_private_key
  prefix                    = var.prefix
  #
  vpc_id                     = local.vpc_id
  subnet_id                  = local.subnet_id
  resource_group_id          = data.ibm_resource_group.group.id
  ssh_key_id                 = local.ssh_key_id
  fp_vsi_floating_ip_address = local.fp_vsi_floating_ip_address
  #fp_vsi_ipv4_address        = local.fp_vsi_ipv4_address
}