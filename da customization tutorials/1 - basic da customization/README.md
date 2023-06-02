# Basic Deployable Architecture Customization


This tutorial customizes the [VSI on VPC landing zone](https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vsi-ef663980-4c71-4fac-af4f-4a510a9bcf68-global) [Deployable Aarchitecgure](https://www.ibm.com/cloud/blog/turn-your-terraform-templates-into-deployable-architectures) (DA) by restricting its configuration to only expose four required configurational properties.  It is doing so by creating a new (custom/private) catalog tile that is re-uses the IBM DA as following:

## Customized Configuration

| VSI on VPC landing zone property | Customized Tile property|
|--|--|
|region | Same as the base DA, but restricted to north america regions (e.g, `us-south` and `us-east`)|
|ibmcloud_api_key| No change|
|prefix          | No change|
|existing-ssh_key| An optional configuration in the base DA, but a required one in the customized tile
|ssh_public_key  | A required configuring in the base DA - not available in the custom DA
|vsi_instance_profile| An optional configuration in the original DA, hard coded to `bx2d-4x16` an not available in the customized DA

## Creating a custom tile

The [tutorial movie](https://ibm.ent.box.com/file/1229039637937?s=kbsg9pqzxt2ry7m8ktztvrs6lvm3frr0) go through the following steps that are required to create a custom tile base on a deployable architecture in the catalog.  This tutorial is uses the UI primarily.  In the general case, publishing and updating private catalog is driven from a (development) pipeline using the catalog CLI/API which you can see in the [automating version catalog publication](../automating%20version%20catalog%20publication/README.md) tutorial.

1. Download the customization bundle from the catalog tile (3:38)
2. Customizing the bundle (4:20)
3. Customizing recap (11:05)
4. Publishing to Git / Creating a release (12:38)
5. Importing to the catalog (14:46)

## Artifacts

You can download the .tgz that was used in this tutorial [here](./basic-tutorial.tgz).

