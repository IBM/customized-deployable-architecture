variable "prefix" {
    type = string
}

variable "region" {
    type = string
    default = "us-south"
}

variable "vault_secrets_app_name" {
    description = "The name of the HCP Vault Secrets application name used."
    type        = string
}

variable "vault_secrets_apikey_secret_name" {
    description = "The name of the secret containing the apikey."
    type        = string
}

variable "vault_secrets_ssh_private_key_secret_name" {
    description = "The name of the secret containing the ssh private key."
    type        = string
}

variable "vault_secrets_ssh_key_secret_name" {
    description = "The name of the secret containing the ssh key."
    type        = string
}

variable "identity_token_file" {
    type = string
}

variable "workload_idp_name" {
    description = "The name of the workload IDP configured in the HCP Platform for Terraform Cloud to use"
    type        = string
}

required_providers {
    ibm = {
        source  = "IBM-Cloud/ibm"
        version = ">=1.45.1"
    }

    # need this to authenticate with HCP to use HCP Vault Secrets
    hcp = {
        source  = "hashicorp/hcp"
        version = "~> 0.79.0"
    }
}

# need this to authenticate with HCP to use HCP Vault Secrets
provider "hcp" "this" {
    config {
        workload_identity {
            resource_name = var.workload_idp_name
            token_file    = var.identity_token_file
        }
    }
}

provider "ibm" {
    ibmcloud_api_key = component.secrets.apikey
    region           = var.region
}

# A data only component that retrieves secrets from HCP Vault Secrets
# an HCP resource deployment that contains the sensitive/secret values needed.  The component must output the values for referencing below.
component "secrets" {
    source = "./vault_secrets"

    inputs = {
        vault_secrets_app_name                    = var.vault_secrets_app_name 
        vault_secrets_secret_name                 = var.vault_secrets_apikey_secret_name
        vault_secrets_ssh_private_key_secret_name = var.vault_secrets_ssh_private_key_secret_name
        vault_secrets_ssh_key_secret_name         = var.vault_secrets_ssh_key_secret_name
    }

    providers = {
        hcp = provider.hcp.this
    }
}

component "apache" {
    # source = ./apache
    source = "https://cm.globalcatalog.test.cloud.ibm.com/api/v1-beta/offering/source/archive//solutions/apache-workload/extension?archive=tgz&flavor=standard&installType=extension&kind=terraform&name=deploy-arch-ibm-gm-custom-apache&version=0.0.74"
    inputs = {
        prefix                     = var.prefix
        ssh_private_key            = component.secrets.ssh_private_key
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

    providers = {
        ibm = provider.ibm.this 
    }
}

component "slz" {
    # source = ./slz
    source = "https://cm.globalcatalog.test.cloud.ibm.com/api/v1-beta/offering/source/archive//solutions/custom-slz?archive=tgz&flavor=babyslz&installType=fullstack&kind=terraform&name=deploy-arch-ibm-gm-test-slz&version=0.0.75"
    inputs = {
        prefix  = var.prefix
        ssh_key = component.secrets.ssh_key
    }

    providers = {
        ibm = provider.ibm.this 
    }
}