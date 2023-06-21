# Extending a deployable architecture

In this tutorial the deployable architecture extension illustrated so far is now implemented as a `fullstack`.  This means that this deployable architecture 
deploys its dependent layer (Custom SLZ) and the extension (Apache webserver) in one operation.

### General design

Ideally this fullstack deployable architecture is at least conceptually just a pasting together of our two building blocks.  The base layer, Custom SLZ, needs to be deployed first and then the extension needs to be 
deployed into that landscape.  Both pieces are already there so the terraform fullstack template would generally look like this.

```
module "custom-slz" {
    .
    .
    .
}

module "custom-apache" {
    .
    .
    .
}
```

For the most part it is that simple but there some considerations that will have to be addressed and those will result in some terraform code changes in the extension.

### Fullstack design considerations

Its important to remember that the general scenario is that the Custom SLZ deployable architecture creates a set of resources, namely an ssh key, a virtual private cloud with subnets, etc. and that 
the extension deploys an Apache webserver by deploying a virtual server within the **workload** VPC deployed by the Custom SLZ.  To do this, dependent resources must exist when they are needed.  The subnets, VPC (and a few 
more resources) must already exist before attempting to deploy the apache virtual server.  The the virtual server must already exist before attempting to deploy the Apache application and so on. 
Terraform does a great job of handling all of the ordering of resource creation when it can determine the dependencies between them.  This is were some planning needs to happen and will be shown in more detail 
below.

But first another consideration with the extension is that it is currently implemented such that it gathers input values from an IBM Schematics workspace that deployed the Custom SLZ layer.  If both 
are being executed within the same terraform template then no workspace is there to be read.  Data values will need to be passed to the extension instead of reading them from a workspace. We want the 
extension to be usable both as an extension deploying into an existing landscape and as a component of a fullstack.  This means the extension needs to know when to attempt to 
read from an existing workspace and when not.

When the extension is being used as a standalone extension, its very simple to use in that very few inputs are needed.  This makes it easy to consume.  Preserving this is important.

### Changes needed

First, lets examine how to implement the extension such that it is able to determine when to read values from an existing workspace and when not to do that.  Recall the extension variable named 
`prerequisite_workspace_id`.  It is defined as a string and does not have a default value so a value is required at runtime.  When the extension is running as an add-on, a non-null value is given 
with the value being a workspace id, ie. "us-south.workspace.globalcatalog-collection.8c0d4826" and the extension retreives what it needs.  When the extension needs to run as part of a fullstack, then 
the value needs to be null since there is not a pre-existing workspace from which to read.  To keep the code within the extension from attempting to read resources that will not be there in fullstack mode 
and be able to reuse the code in extension mode, an addition is made to the `data` queries.  For example,
```
data "ibm_schematics_workspace" "schematics_workspace" {
  # only query the resource if a workspace id was given.  means this is running as an extension.
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}
```
The addition of `count  = var.prerequisite_workspace_id == "" ? 0 : 1` means the query will only happen if the value of the `prerequisite_workspace_id` variable is not null.  Adding that line to 
each of the `data` queries in the extension makes the code reusable and prevents an error when running in fullstack mode.  The code now only attempts to read a workspace when given a workspace id value by 
the consumer.

Next, there needs to be a way to get the data values that previously came from reading the workspace.  These were the ids values for the subnet, vpc, resource group id.  When running as a 
fullstack there is not a workspace to read outputs but rather we can use the outputs directly from the Custom SLZ deployable architecture and pass in the id values directly to the extension.  For 
example:

```
locals {
  # lets deploy the workload on the "workload" vpc in the base layer. 
  vpc_type = "workload"

  # construct the name of the targeted vpc and then find it in the output 
  vpc_name = join("-", [var.prefix, local.vpc_type, "vpc"])
  vpc_id = [for vpc in module.custom_slz.vpc_data : vpc.vpc_id if vpc.vpc_name == local.vpc_name][0]

  # construct the name of the targeted subnet and then find it in the output
  subnet_name = join("-", [var.prefix, local.vpc_type, "vsi-zone-1"])
  subnet_id = [for subnet in module.custom_slz.subnet_data : subnet.id if subnet.name == local.subnet_name][0]

  # construct the name of the ssh key and then find it in the output
  ssh_key_name = "ssh-key"
  ssh_key_id = [for ssh_key in module.custom_slz.ssh_key_data : ssh_key.id if ssh_key.name == local.ssh_key_name][0]

  # construct the name of the jump box and then find it in the output
  fp_vsi_name = join("-", [var.prefix, "jump-box-1"])
  fp_vsi_floating_ip_address = [for fp in module.custom_slz.fip_vsi : fp.floating_ip if fp.name == local.fp_vsi_name][0]

  # get the resource group id that was used by the custom slz layer from the outputs
  resource_group_id = values(module.custom_slz.resource_group_data)[0]
}
```

The above code combines the method outlined in a previous tutorial and constructs the name of the resource using the prefix and known suffix.  Then the name is looked up 
in the output of the Custom SLZ module.  The end result is that the extension is passed values for the resources ids instead of finding them itself.  The final version 
of the extension becomes:

```locals {

  vpc_type = "workload"

  # Determine where the workspace is for the prerequisite deployment.  The location is the first part of the
  # pre-requisite workspace's id string.  The workspace id is not provided when running as a full stack so check for a null value.
  location = var.prerequisite_workspace_id != "" ? regex("^[a-z/-]+", var.prerequisite_workspace_id ) : ""
}

data "ibm_schematics_workspace" "schematics_workspace" {
  # only query the resource if a workspace id was given.  means this is running as an extension.
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}

data "ibm_schematics_output" "schematics_output" {
  # only query the resource if a workspace id was given.  means this is running as an extension.
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
  template_id  = data.ibm_schematics_workspace.schematics_workspace[0].runtime_data[0].id
}

locals {
  slz_output = var.prerequisite_workspace_id != "" ? jsondecode(data.ibm_schematics_output.schematics_output[0].output_json) : null
  # prefix will either come from the prerequisite's workspace (extension) or it will come from a variable (fullstack).
  prefix      = var.prerequisite_workspace_id != "" ? local.slz_output[0].prefix.value : var.prefix
  subnet_name = join("-", [local.prefix, local.vpc_type, "vsi-zone-1"])
}

data "ibm_is_subnet" "subnet" {
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  name = local.subnet_name
}

data "ibm_is_ssh_key" "ssh-key" {
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  name = join("-", [local.prefix, "ssh-key"])
}

data "ibm_is_floating_ip" "jump-box-fip" {
  count  = var.prerequisite_workspace_id == "" ? 0 : 1
  name = join("-", [local.prefix, "jump-box-1-fip"])
}

# the image resource is always present and it is ok to query it.
data "ibm_is_image" "image" {
  name = var.image
}

locals {
  resource_group_id = var.resource_group_id != "" ? var.resource_group_id : data.ibm_is_subnet.subnet[0].resource_group
  subnet_id  = var.subnet_id != "" ? var.subnet_id : data.ibm_is_subnet.subnet[0].id
  vpc_id     = var.vpc_id != "" ? var.vpc_id : data.ibm_is_subnet.subnet[0].vpc
  ssh_key_id = var.ssh_key_id != "" ? var.ssh_key_id : data.ibm_is_ssh_key.ssh-key[0].id
  fp_vsi_floating_ip_address = var.fp_vsi_floating_ip_address != "" ? var.fp_vsi_floating_ip_address : data.ibm_is_floating_ip.jump-box-fip[0].address
}

data "ibm_is_subnet" "by-subnet-id" {
  identifier = local.subnet_id
}

module "slz_vsi" {
  source                     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi.git?ref=v2.0.0"
  resource_group_id          = local.resource_group_id
  image_id                   = data.ibm_is_image.image.id
  create_security_group      = true
  security_group             = var.appSecurityRules
  tags                       = []
  subnets                    = [{"name": local.subnet_name, "id": local.subnet_id, "zone":data.ibm_is_subnet.by-subnet-id.zone, "cidr": data.ibm_is_subnet.by-subnet-id.ipv4_cidr_block}]
  vpc_id                     = local.vpc_id
  prefix                     = join("-", [local.prefix, "apache-webserver"])
  machine_type               = "cx2-2x4"
  user_data                  = var.workLoadInitScript
  boot_volume_encryption_key = null
  vsi_per_subnet             = 1
  ssh_key_ids                = [local.ssh_key_id]
}

resource "null_resource" "execute_ansible" {
  depends_on = [module.slz_vsi]
    
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = local.fp_vsi_floating_ip_address
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
```

This version is able to function both as an extension that reads input values from an existing workspace as well as part of a fullstack deployable architecture where it is passed 
id values of the resources it needs.

The fullstack terraform is this

```
#
#
module "custom_slz" {
    source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/custom-slz?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=babyslz&kind=terraform&name=custom-deployable-arch&version=^0.0.51"
    prefix           = var.prefix
    ssh_key          = var.ssh_key
    ibmcloud_api_key = var.ibmcloud_api_key
}

#
# this implementation is such that the apache workload module is deployed in the same terraform apply
# operation as the the dependency layer - custom slz.  Therefore, the information needed by the 
# workload apply comes from direct outputs of the custom slz.
#

locals {
  # lets deploy the workload on the "workload" vpc in the base layer. 
  vpc_type = "workload"

  # construct the name of the targeted vpc and then find it in the output 
  vpc_name = join("-", [var.prefix, local.vpc_type, "vpc"])
  vpc_id = [for vpc in module.custom_slz.vpc_data : vpc.vpc_id if vpc.vpc_name == local.vpc_name][0]

  # construct the name of the targeted subnet and then find it in the output
  subnet_name = join("-", [var.prefix, local.vpc_type, "vsi-zone-1"])
  subnet_id = [for subnet in module.custom_slz.subnet_data : subnet.id if subnet.name == local.subnet_name][0]

  # construct the name of the ssh key and then find it in the output
  ssh_key_name = "ssh-key"
  ssh_key_id = [for ssh_key in module.custom_slz.ssh_key_data : ssh_key.id if ssh_key.name == local.ssh_key_name][0]

  # construct the name of the jump box and then find it in the output
  fp_vsi_name = join("-", [var.prefix, "jump-box-1"])
  fp_vsi_floating_ip_address = [for fp in module.custom_slz.fip_vsi : fp.floating_ip if fp.name == local.fp_vsi_name][0]

  # get the resource group id that was used by the custom slz layer from the outputs
  resource_group_id = values(module.custom_slz.resource_group_data)[0]
}

module "custom_apache" {
  source                     = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/apache-workload/extension?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=standard&kind=terraform&name=custom-apache&version=^0.0.51&installType=extension"
  ### directly use this as an extension by supplying just these values.
  ibmcloud_api_key           = var.ibmcloud_api_key
  prerequisite_workspace_id  = var.prerequisite_workspace_id
  ssh_private_key            = var.ssh_private_key
  ### or provide all of these, above 3 and these below, values when using this within a fullstack terrform.
  prefix                     = var.prefix
  vpc_id                     = local.vpc_id
  subnet_id                  = local.subnet_id
  resource_group_id          = local.resource_group_id
  ssh_key_id                 = local.ssh_key_id
  fp_vsi_floating_ip_address = local.fp_vsi_floating_ip_address
}
```

Note that the use of the terraform directive `depends_on` was not used to make the extension module wait for the Custom SLZ module to finish creating resources.  If it were used there 
would be an error like this:
```
"Module contains provider configuration" "Providers cannot be configured within modules using count, for_each or depends_on."
```
The extension code was written to be a single terraform that could be used both as an extension and in a fullstack so it uses the `count` function to guard against querying 
a resource that is not there when running as a fullstack.  Also both the Custom SLZ and the extension are packaged with a provider configuration.

## Conclusion

Could this have been done differently, maybe.  This approach definitely works.  