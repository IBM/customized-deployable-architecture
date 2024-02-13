# Extending a deployable architecture

In this tutorial the deployable architecture extension illustrated in the first deployable architecture extension tutorial is modified to highlight a different method for obtaining 
needed information about the deployed resources from the dependent layer created by Custom SLZ.  Why is this being done?  This is being done to gain an understaning of this 
method so that it can be used as a building block which is used in the next tutorial.

In the first tutorial, most of the information needed was read from the Custom SLZ workspace.  Further, within the outputs, details were obtained by reading elements of an array 
and assumptions were made as to which element was to be read.  This was done in that tutorial for simplicity and to illustrate the method.  Also to emphasize the close relationship 
between the outputs of a dependent layer and the subsequent layers that build upon it.  This tutorial and the next will illustrate additional methods.

This tutorial focuses on using names of resources to query them and retreive properties.

The Custom SLZ deployable architecture is a customizations of the IBM VSI on VPC landing zone deployable architecture.  When the VSI on VPC landing zone deployable architecture creates resources, 
it utilizes a naming convention which consists of a string prefix concatentated with a suffix that is specific to the type of resource being created.  The prefix value is the same value as the input value 
provided to Custom SLZ and it is emitted in the outputs for subsequent use by extensions.  Knowing the prefix value and the string values of the suffixes is a convenient way to be able to 
lookup a resource.  For example, the ssh key created is named `{prefix}-ssh-key` and the workload vpc is named `{prefix}-workload-vpc`.  A partial list of suffixes used by the VSI on VPC landing zone deployable 
architecture is:

| Resource | Name | Notes|
|:---|:---|:---|
|workload vpc|{prefix}-workload-vpc||
|ssh key|{prefix}-ssh-key||
|jump box|{prefix}-jump-box-1||
|floating point IP address for jump box|{prefix}-jump-box-1-fip||
|subnet|{prefix}-{vpc type}-vsi-zone-1|VPC type is one of `workload`, `management`, `edge`.  Only `workload` is used for Custom SLZ.  For multi-zone VPCs, then `zone-{zone number}`|

With the list above, the extension may be modified to retrieve just one value from the workspace outputs - the `prefix` value.  Using that the deployed resources of interest maybe 
queried directly.  The terraform code becomes this to construct the names of the resources.

```
locals {
  # Determine where the workspace is for the pre-requisite deployment.  The location is the first part of the
  # pre-requisite workspace's id string.  
  location = regex("^[a-z/-]+", var.prerequisite_workspace_id )

  # these could be future outputs from Custom SLZ
  target_vpc_type       = "workload"
  target_subnet_suffix  = "vsi-zone-1"
  target_ssh_key_suffix = "ssh-key"
  target_jump_box_fip_suffix = "jump-box-1-fip"
}

.
.
.

locals {
  # access the output from the workspace which is in json format so decode the json.  This will then allow us to retrieve specific values.
  workspace_outputs = jsondecode(data.ibm_schematics_output.schematics_output.output_json)
  workspace_output = local.workspace_outputs[0]

  # refer to the structure of the output to understand how these values are retrieved.  See the Readme.
  prefix       = local.workspace_output.prefix.value
  subnet_name  = join("-", [local.prefix, local.target_vpc_type, local.target_subnet_suffix])
  ssh_key_name = join("-", [local.prefix, local.target_ssh_key_suffix])
  fp_vsi_floating_ip_address_name = join("-", [local.prefix, local.target_jump_box_fip_suffix])
}
```

To query the resources by name:

```
data "ibm_is_subnet" "subnet" {
  name = local.subnet_name
}

data "ibm_is_ssh_key" "ssh-key" {
  name = local.ssh_key_name
}

data "ibm_is_floating_ip" "jump-box-fip" {
  name = local.fp_vsi_floating_ip_address_name
}

data "ibm_is_image" "image" {
  name = var.image
}

locals {
  resource_group_id = data.ibm_is_subnet.subnet.resource_group
  subnet_id         = data.ibm_is_subnet.subnet.id
  vpc_id            = data.ibm_is_subnet.subnet.vpc
  ssh_key_id        = data.ibm_is_ssh_key.ssh-key.id
  fp_vsi_floating_ip_address = data.ibm_is_floating_ip.jump-box-fip.address
}
```
In the above as an example, a query is made to the resource type `ibm_is_subnet` that is named using the naming convention discussed above.  From that resource, we obtain multiple properties.  To get a full list of the properties available from querying any of the above resources, refer to the documentation for the [IBM terraform provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs).

The remainder of the code is unchanged from the first tutorial now that we have the ids of the resources we need to created the virtual server.  See the file `main.tf` for the full example.

