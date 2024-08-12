locals {

  vpc_type = "workload"

  # determine if values are coming from input variables directly or if they are to be retrieved from
  # a Schematics workspace's output values.  Use a workspace if provided an id of a workspace that is
  # non empty string and has 4 segments delimited by a '.'
  use_workspace_info = (var.prerequisite_workspace_id != "" && length(split(".", var.prerequisite_workspace_id)) >= 3) ? 1 : 0

  # Determine where the workspace is for the prerequisite deployment.  The location is the first part of the
  # pre-requisite workspace's id string.  The workspace id is not provided when running as a full stack so check for a null value.
  location = local.use_workspace_info == 1 ? regex("^[a-z/-]+", var.prerequisite_workspace_id ) : ""
}

data "ibm_schematics_workspace" "schematics_workspace" {
  # only query the resource if a workspace id was given.
  count  = local.use_workspace_info
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}

data "ibm_schematics_output" "schematics_output" {
  # only query the resource if a workspace id was given.
  count  = local.use_workspace_info
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
  template_id  = data.ibm_schematics_workspace.schematics_workspace[0].runtime_data[0].id
}

# use specific output values from the deployment workspace of the dependent terraform template. 
#   named outputs from dependent layer: 
#      prefix
#      workload_subnet_id
#      resource_group_id
#      workload_vpc_id
#      ssh_key_id
#      workload_vsi_fip
locals {
  # retrieve all of the workspace output values in json form.
  slz_output = local.use_workspace_info == 1 ? jsondecode(data.ibm_schematics_output.schematics_output[0].output_json) : null

  # access individual output values from a workspace if using a workspace.  Otherwise use the input variable values.
  prefix      = local.use_workspace_info == 1 ? local.slz_output[0].prefix.value : var.prefix
  subnet_id   = local.use_workspace_info == 1 ? local.slz_output[0].workload_subnet_id.value : var.subnet_id
  resource_group_id = local.use_workspace_info == 1 ? local.slz_output[0].resource_group_id.value : var.resource_group_id
  vpc_id      = local.use_workspace_info == 1 ? local.slz_output[0].workload_vpc_id.value : var.vpc_id
  ssh_key_id  = local.use_workspace_info == 1 ? local.slz_output[0].ssh_key_id.value : var.ssh_key_id
  fp_vsi_floating_ip_address = local.use_workspace_info == 1 ? local.slz_output[0].workload_vsi_fip.value : var.fp_vsi_floating_ip_address
}

# the image resource is always present and it is ok to query it.  query the image to obtain the 
# image id.
data "ibm_is_image" "image" {
  name = var.image
}

# query the subnet resource to obtain the cidr block, zone and name attributes
data "ibm_is_subnet" "by-subnet-id" {
  identifier = local.subnet_id

  lifecycle {
    precondition {
      condition     = local.subnet_id != ""
      error_message = "Unable to query subnet resource.  The subnet id value must not be null or an empty string."
    }
  }
}

# use this block to validate that the local variables all have non-null values.
output "all-inputs" {
  value = "All input values were given."
    precondition {
      condition     = local.prefix != ""
      error_message = "The prefix value must not be null or an empty string."
    }
    precondition {
      condition     = local.resource_group_id != ""
      error_message = "The resource_group_id value must not be null or an empty string."
    }
    precondition {
      condition     = local.vpc_id != ""
      error_message = "The vpc_id value must not be null or an empty string."
    }
    precondition {
      condition     = local.ssh_key_id != ""
      error_message = "The ssh_key_id value must not be null or an empty string."
    }
    precondition {
      condition     = local.fp_vsi_floating_ip_address != ""
      error_message = "The fp_vsi_floating_ip_address value must not be null or an empty string."
    }
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git?ref=v3.3.0"
  resource_group_id          = local.resource_group_id
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = ["apache"]
  subnets                    = [{"name": data.ibm_is_subnet.by-subnet-id.name, "id": local.subnet_id, "zone":data.ibm_is_subnet.by-subnet-id.zone, "cidr": data.ibm_is_subnet.by-subnet-id.ipv4_cidr_block}]
  vpc_id                     = local.vpc_id
  prefix                     = join("-", [local.prefix, "apache-webserver"])
  machine_type               = "cx2-2x4"
  user_data                  = null
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [local.ssh_key_id]
}
