# this is the output from an SLZ deployment.
variable "customSecInfra" {
  type = string
  default = "customSecInfra.json"
}

# install script for the application to be installed on the VSI
variable "appInstallScript" {
  type = string
  default = "appInstallScript.sh"
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

# configure the terraform provider and direct it to the same region where the SLZ resources 
# were deployed
variable "region" {
    type = string
    default = "eu-de"
}