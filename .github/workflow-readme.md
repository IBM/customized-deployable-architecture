# Sample workflows

This Readme provides details regarding the git Actions found in this repository. Both action/workflows illustrate the onboarding of an offering version to
 an IBM Cloud catalog.  The onboarding process includes importing to a catalog, running validation, scanning the resources with the Security and Compliance 
 service and publishing within the catalog.

There are two implementations, one implements the process with standard cli commands that interact with an IBM Cloud catalog.  The other implementation 
illustrates how the same process may be implemented using an IBM Cloud catalog and an IBM Project.  The workflows are designed to be initiated everytime 
a new release is created within the repo.  

## Workflows

### Basic onboarding workflow

This is a simple workflow that utilizes off the shelf tools executed from a script.  This workflow requires the configuration of a repo secret that has a value 
of an IBM Cloud account's API key that has sufficient IAM permissions to provision resources.  See the Git documentation to configure the secret.  
The secret should be named IBMCLOUD_API_KEY.  The remaining settings are defined within the workflow definition file - publish-pipeline.yml.  

The steps within the workflow are the following.

1.  Git checkout - get the contents of the release onto the worker machine provisioned to run this workflow.
2.  Install and setup IBMCLOUD Cli - perform set up needed for the remaining steps by installing the ibmcloud cli and needed plugins.
3.  Upload, validate, scan and publish custom-deployable-arch - deploys resources for a custom architecture.
4.  Upload, validate, scan and publish custom-apache extension - deploys an Apache server onto the custom architecture from step 3.
5.  Cleanup deployed resources - destroys all resources created in steps 3 and 4.

### Project based onboarding workflow

This workflow highlights the coordination of IBM Catalog, IBM Projects and IBM Schematics to illustrate the EPX process flow.