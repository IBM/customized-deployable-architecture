# Custom Secure infrastructure on VPC 

The repo provides an example to customize the public IBM [Secure infrastructure on VPC for regulated industries](https://cloud.ibm.com/catalog/content/slz-vpc-with-vsis-a87ed9a5-d130-47a3-980b-5ceb1d4f9280-global) deployable architecture by [enforcing a set of values](https://github.com/IBM/customized-deployable-architecture/blob/main/main.tf#L8) and providing a [json override](override.json) file for modifying the deployment architecture pattern with out the need to modify the actual code.  
In addition, this repo provides: 
   * A [module](/examples/app/extension/main.tf) that extends an existing infrastrucutre with a VSI running an apache server
   * A [blueprint](examples/app/full/blueprint/full.yaml) that will provision both the infrastructure an the apache **Module** as a single blueprint


![Custom topology](/images/custom-slz.svg)


## This example shows how:  


1. The author of this deployable architecture can define a fully custom topology via an [override json file](override.json) file baked into the deployable architecture. The override adds a **floating IP** access to the jumpbox VSI.
2. Restricts the ability for the consumers of the custom deployable architecture to change the _region_ property, where the regions is pre-set to `eu-de`. Also, a smaller set of input values are surfaced to consumers (see [variables.tf](variables.tf))
3. Automation [example](.github/workflows) to publish the custom deployable architecture as a private custom catalog entry.

![CustomTile](/images/custom-tile.png)

4. Ability to deploy both the custom infrastructure with an apache server, as well as extend an existing infrastructure with an apache server.




