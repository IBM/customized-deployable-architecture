# Customized deployable architecture

## Tutorials
This repo contains tutorials that step through the concept of a deployable architecture, how to develop one, how to customize an existing one found in the IBM catalog, and more.  The tutorials are 
a work in progress and are continually being improved upon.  Tutorials so far include:
-  [deployable architecture overview](./da%20customization%20tutorials/0%20-%20da%20overview/)
-  [deployable architecture deployment lifecycle](./da%20customization%20tutorials/1%20-%20da%20deployment%20lifecycle/)
-  [basic depployable architecture customization](./da%20customization%20tutorials/2%20-%20basic%20da%20customization/)
-  [using an override to customize a deployable architecture](./da%20customization%20tutorials/3%20-%20override%20da%20customization/)
-  [developing an extension for a deployable architecture](./da%20customization%20tutorials/4%20-%20extending%20a%20da/)

### Coming soon.  
Future tutorials will include how to setup Security and Compliance scanning on the IBM Cloud and how to record the results as well a tutorial on the overall deployable architecture development lifecycle.

## Example customized deployable architectures
This repo also provides an [example of a customization](./solutions/custom-slz) of the IBM deployable architecture [VSI on VPC landing zone](https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vsi-ef663980-4c71-4fac-af4f-4a510a9bcf68-global).  This customization is a minor customization but illustrates how easy it is accomoplish making a change that is suited to a particular need.  The customized deployable architecture still deploys a base networking layer with a Virtual Private Cloud but is now limited to the 'us-east' IBM Cloud region.   

In addition to that example, this repo also contains an example of a deployable architecture that extends the base deployment by deploying a workload.  The workload is a virtual server that is deployed within the VPC created by the base and it runs an Apache web server.  There are two implementations of this deployable architecture, an ['extension'](./solutions/apache-workload/extension/) and a ['fullstack'](./solutions/apache-workload/fullstack/).  A deployable architecture that is an 'extension' requires that another offering be deployed prior to its own deployment.  It has a dependency.   A deployable architecture that is a 'fullstack' does not have any dependencies and will deploy the entire solution.

![Custom topology](/images/baby-slz.svg)

Also provided are examples of automation that perform the tasks to onboard, validate and publish to an IBM Cloud catalog.  One is implemented as scripts that execute as part of a Github action which triggers on the creation of a release, the other is an IBM Cloud toolchain.

# The customization process
## This example shows how:  


1. Create a custom deployable architecture and deploy it as a custom tile to the IBM cloud catalog.
1. Create a custom extension that extends the custom deployable architecture (based on the IBM VSI module) to deploy an Apache server.
1. create a pipeline that will publish the custom architecture and apache server as private solutions on the IBM public catalog.

![CustomTile](/images/custom-tile.png)


Catalog tiles:

* custom-deployable-arch is a generic deployable architecture for the network landscape.
* custom-apache is a deployable architecture as a workload which runs a secure apache server.

The Apache workload tile has both an extension and a fullstack implemenation as variations of the deployable architecture.
