# Custom Secure infrastructure on VPC 

The repo provides an example to customize the [Secure infrastructure on VPC for regulated industries](https://cloud.ibm.com/catalog/content/slz-vpc-with-vsis-a87ed9a5-d130-47a3-980b-5ceb1d4f9280-global) deployable architecture by [enforcing value](https://github.com/IBM/customized-deployable-architecture/blob/main/main.tf#L8) and providing a [json override](override.json) file.



This example shows how:  

1. The author of this deployable architecture can define a fully custom topology via an [override json file](override.json) file baked into the deployable architecture. The override adds an **edge** vpc to the _Secure infrastructure_ and adds a **floating IP** access to the jumpbox VSI.
2. Restricts the ability for the consumers of the custom deployable architecture to change the _region_ property, where the regions is pre-set to `eu-de`. Also, a smaller set of input values are surfaced to consumers (see [variables.tf](variables.tf))
3. Automation [example](.github/workflows) to publish the custom deployable architecture as a private custom catalog entry.

The topology in this example builds starting from the standard Secure infrastructure on VPC topology, and adds the following:
1. Deploy an edge VPC with 3 subnets with:
   - 1 VSI in one of the 3 subnet
   - A VPC Loadbalancer in the edge vpc, exposing publicly the VSI.
2. Deploy a 'jump-box' VSI in the management VPC, exposing a public floating IP.


![Custom topology](custom-slz-with-edge.svg)

