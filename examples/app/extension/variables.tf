variable "config" {
    type = string
}

variable "appInstall" {
    type = string
}

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "region" {
    type = string
}

variable "image" {
  default = "ibm-ubuntu-20-04-4-minimal-amd64-2"
}