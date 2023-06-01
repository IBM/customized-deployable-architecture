# Custom Secure infrastructure on VPC 

This repo provides an example customizing the public IBM [VSI on VPC landing zone](https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vsi-ef663980-4c71-4fac-af4f-4a510a9bcf68-global) deployable architecture by [enforcing a set of values](https://github.com/IBM/customized-deployable-architecture/blob/main/main.tf#L8) and providing a [json override](override.json) file for modifying the deployment architecture pattern with out the need to modify the actual code.  

This is a example that illustrates simple customizations.
1. the region has been set to the value "us-east" as an exmple of locking down a deployment to an approved deployment region.
2. a json override file has been provided to affect the deployment of resources, as supported by the IBM [VSI on VPC landing zone](https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vsi-ef663980-4c71-4fac-af4f-4a510a9bcf68-global) deployable architecture.

![Custom topology](/images/baby-slz.svg)
