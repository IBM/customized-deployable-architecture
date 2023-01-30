# Customizing a Solution 

This repo provides an example customizing the public IBM [Secure infrastructure on VPC for regulated industries](https://cloud.ibm.com/catalog/content/slz-vpc-with-vsis-a87ed9a5-d130-47a3-980b-5ceb1d4f9280-global) deployable architecture by [enforcing a set of values](https://github.com/IBM/customized-deployable-architecture/blob/main/main.tf#L8) and providing a [json override](override.json) file for modifying the deployment architecture pattern with out the need to modify the actual code.  
In addition, this repo provides: 
   * A [module](/examples/app/extension/main.tf) that extends the custom infrastrucutre with a VSI running an apache server
   * A [blueprint](examples/app/full/blueprint/full.yaml) that will provision both the custom infrastructure and the apache **Module** as a single blueprint


![Custom topology](/images/custom-slz.svg)


## This example shows how:  


1. Create a custom deployable architecture and deploy it as a custom tile to the IBM cloud catalog.
1. Create a custom module that extends the custom deployable architecture (based on the IBM VSI module) to deploy an Apache server.
1. Create a blueprint deploys both the custom module and custom deployable architecture's base infrastructure and an apache server on top of it
1. create a pipeline that will publish the custom architecture and apache server as private solutions on the IBM public catalog.

![CustomTile](/images/custom-tile.png)


Catalog tiles:

* Custom Secure infra is a generic deployable architecture for the network landscape.
* Apache App workload is a deployable architecture to for running a secure apache server.

The Apache tile will hold both a terraform and a blueprint.  The blueprint is used to deploy both the app infra and the base deployable architecture.  The terraform template is use in the case that you want the apache server to run on an existing Secure Infra deployment.


Publish Pipeline

Included in this example is a Github Action to illustrated automated publishing to an IBM catalog.  The supplied action makes the following assumptions as pre-requisites.
1. a secret in the repo has been configured for a IBM Cloud api key for an account that has sufficient IAM permissions to provision resources.
1. the Action imports, validates, publishes new versions as they are created when a git release is created.  It is assumed that the offerings have already been created in the target catalog which is done only once.
