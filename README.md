# Custom Secure Landing Zone

Customizing example for the [landing zone solution](https://cloud.ibm.com/catalog/content/slz-vpc-with-vsis-a87ed9a5-d130-47a3-980b-5ceb1d4f9280-global) using parameters and a json overrides.



This example shows how:
1. The author of this solution can define a fully custom topology via an [override.json](override.json) file baked into the solution
2. Restrict the ability for the consumers of the custom solution to change configuration: the topology defined by the author cannot be changed by consumers, and the region is set to 'eu-de' only. A small number of input variables are surfaced to consumers (see [variables.tf](variables.tf))

The topology in this example builds starting from the standard SLZ topology, and adds the following:
1. Deploy an edge VPC with 3 subnets with:
   - 1 VSI in one of the 3 subnet
   - A VPC Loadbalancer in the edge vpc, exposing publicly the VSI.
2. Deploy a 'jump-box' VSI in the management VPC, exposing a public floating IP.


![Custom topology](https://github.com/gmendel/deployable-architecture/blob/main/custom-slz-with-edge.svg)

