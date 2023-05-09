module "custom_slz" {
    source           ="https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=standard&kind=terraform&name=custom-apache&version=0.0.48"
    #source           = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/custom-deployable-arch?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=customedge&kind=terraform&name=custom-deployable-arch&version=0.0.28"
    prefix           = var.prefix
    ssh_key          = var.ssh_key
    ibmcloud_api_key = var.ibmcloud_api_key
}

module "custom_apache" {
  #source                    = "https://cm.globalcatalog.cloud.ibm.com/api/v1-beta/offering/source//solutions/custom-apache/workload-only/ansible?archive=tgz&catalogID=33eb1d96-dfb4-4d60-a21a-c376ed0c89c3&flavor=standard&kind=terraform&name=custom-apache&version=0.0.28"
  source  = "../extension"
  ibmcloud_api_key          = var.ibmcloud_api_key
  prerequisite_workspace_id = var.prerequisite_workspace_id
  ssh_private_key           = var.ssh_private_key
  prefix                    = var.prefix
}