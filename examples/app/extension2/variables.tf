
# initialize the VSI to be an Ansible managed node by installing python
variable "workLoadInitScript" {
  type    = string
  default = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get --yes install python
EOF
}

# the OS image to install on the VSI
variable "image" {
  default = "ibm-ubuntu-20-04-4-minimal-amd64-2"
}

# API key with sufficient permissions to deploy resources 
variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

# configure the terraform provider and direct it to the same region where the 
# custom secure infrastructure resources were deployed.
variable "region" {
  type    = string
  default = "us-east"
}

# prefix used when deploying resources in the custom secure infrastructure step
variable "prefix" {
  type        = string
  description = "A unique identifier for resources. Must be the same one that is used in the base infrastructure."
}
