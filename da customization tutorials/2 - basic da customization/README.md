# Basic Deployable Architecture Customization


This tutorial customizes the [VSI on VPC landing zone](https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vsi-ef663980-4c71-4fac-af4f-4a510a9bcf68-global) [Deployable Architecture](https://www.ibm.com/cloud/blog/turn-your-terraform-templates-into-deployable-architectures) by restricting its configuration to expose four required configurational properties.  It is doing so by creating a new (custom/private) catalog tile that based (wrapping) the IBM published _VSI on VPC landing zone_ deployable architecture as following:

## Customized Configuration

IBM tile vs. Customized tile properties:

| VSI on VPC landing zone | Customized Tile |
|--|--|
|region | Same as the base deployable architecture, but restricted to North America regions (e.g, `us-south` and `us-east`)|
|ibmcloud_api_key| No change|
|prefix          | No change|
|existing-ssh_key| An optional configuration in the base deployable architecture, but a required one in the customized tile |
|ssh_public_key  | A required configuration in the base deployable architecture - not available in the custom deployable architecture |
|vsi_instance_profile| An optional configuration in the original deployable architecture, hard coded to `bx2d-4x16` and not available in the customized deployable architecture |
| optional properties | no optional properties |

## Creating a custom tile

The [tutorial movie](https://ibm.ent.box.com/file/1229039637937?s=kbsg9pqzxt2ry7m8ktztvrs6lvm3frr0) goes through the following steps that are required to create a custom tile base on a deployable architecture already in the catalog.  This tutorial is uses the IBM Cloud console UI primarily.  In the general case, publishing and updating private catalog is driven from a (development) pipeline using the catalog CLI/API which you can see in the [automating version catalog publication](../automating%20version%20catalog%20publication/README.md) tutorial.

1. Download the customization bundle from the catalog tile (3:38)
2. Customizing the bundle (4:20)
3. Customizing recap (11:05)
4. Publishing to Git / Creating a release (12:38)
5. Importing to the catalog (14:46)

## Artifacts

You can download the .tgz that was used in this tutorial [here](./basic-tutorial.tgz).

