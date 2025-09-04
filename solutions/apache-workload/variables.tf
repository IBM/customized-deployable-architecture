
# the OS image to install on the VSI
variable "image" {
  description = "Available images may be found by using ibmcloud is images cli command."
  type    = string
  default = "ibm-ubuntu-22-04-5-minimal-amd64-1"
}

# API key with sufficient permissions to deploy resources 
variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The IBM Cloud region to use for deploying resources."
  type = string
}
variable "prefix" {
  type    = string
  description = "Prefix string for resources created."
}

variable "ssh_private_key" {
  description = "Private SSH key (RSA format) that is paired with the public ssh key.  Will be used by Ansible to access the VSI. If using the cloud it is not necessary but if running locally then entered data must be in [heredoc strings format](https://www.terraform.io/language/expressions/strings#heredoc-strings). The key is not uploaded or stored. For more information about SSH keys, see [SSH keys](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)."
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "The id of the VPC where the virtual server is to be created."
  type = string
}

variable "subnet_id" {
  description = "The id of the subnet within the VPC where the virtual server is to be created."
  type = string
}

variable "resource_group_id" {
  description = "The id of the resource group where the virtual server is to be created."
  type = string
}

variable "ssh_key_id" {
  description = "The id of the public ssh key that pairs with the private ssh key deployed with the jump box."
  type = string
}

variable "fp_vsi_floating_ip_address" {
  description = "The floating point IP address of the jump box."
  type = string
}