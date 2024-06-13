variable "prefix" {
    type = string
}

variable "ssh_key" {
    type = string
}

variable "ssh_private_key" {
    type = string
    sensitive = true
}

variable "apikey" {
    type = string
    sensitive = true
}

variable "region" {
    type = string
    default = "us-south"
}

required_providers {
    ibm = {
        source  = "IBM-Cloud/ibm"
        version = ">=1.45.1"
    }
}

provider "ibm" {
    ibmcloud_api_key = var.apikey
    region           = var.region
}

component "apache" {
    # source = ./apache
    source = "https://cm.globalcatalog.test.cloud.ibm.com/api/v1-beta/offering/source/archive//solutions/apache-workload/extension?archive=tgz&flavor=standard&installType=extension&kind=terraform&name=deploy-arch-ibm-gm-custom-apache&version=0.0.74"
    inputs = {
        prefix                     = var.prefix
        ssh_private_key            = var.ssh_private_key
        prerequisite_workspace_id  = ""
        fp_vsi_floating_ip_address = component.slz.workload_vsi_fip
        resource_group_id          = component.slz.resource_group_id
        ssh_key_id                 = component.slz.ssh_key_id
        subnet_id                  = component.slz.workload_subnet_id
        vpc_id                     = component.slz.workload_vpc_id
        region                     = var.region
        image                      = "ibm-ubuntu-22-04-4-minimal-amd64-1"
        appSecurityRules           = "{\"name\":\"httpd-sg\",\"rules\":[{\"name\":\"httpd-port-80\",\"direction\":\"inbound\",\"source\":\"0.0.0.0/0\",\"tcp\":{\"port_max\":80,\"port_min\":80}},{\"name\":\"ssh-port-22\",\"direction\":\"inbound\",\"source\":\"0.0.0.0/0\",\"tcp\":{\"port_max\":22,\"port_min\":22}},{\"name\":\"outbound-off\",\"direction\":\"outbound\",\"source\":\"0.0.0.0/0\"},{\"name\":\"httpd-port-443\",\"direction\":\"inbound\",\"source\":\"0.0.0.0/0\",\"tcp\":{\"port_max\":443,\"port_min\":443}}]}"
    }
}

component "slz" {
    # source = ./slz
    source = "https://cm.globalcatalog.test.cloud.ibm.com/api/v1-beta/offering/source/archive//solutions/custom-slz?archive=tgz&flavor=babyslz&installType=fullstack&kind=terraform&name=deploy-arch-ibm-gm-test-slz&version=0.0.75"
    inputs = {
        prefix  = var.prefix
        ssh_key = var.ssh_key
    }
}