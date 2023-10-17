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

This workflow highlights the coordination between IBM Catalog, IBM Projects and IBM Schematics to illustrate the EPX process flow.  Here the 
offering version is imported to a catalog and a configuration created in a Project enabling the project to track its validation status.  Prior 
to the execution of the workflow some basic setup is needed between the catalog and project.

Before executing the workflow - one time setup
- create the catalog
- create the project
- Link the catalog and the project by editing the catalog details.  In this workflow, the authorization is an IBM Cloud api key.  Define it as part of the catalog details with the project.


#### Security and Compliance scanning

This workflow also utilizes the IBM Security and Compliance service to scan the provisioned resources and validate the claimed security controls.  This requires an instance of Security and Compliance (SCC) on an IBM Cloud account.  

Additional secrets have been defined in this repository to hold the id of the account that owns the SCC instance and to store an api key for that same account.  The SCC controls that are claimed are specified in the `ibm_catalog.json` file in the compliance section.  Scan results are applied 
to each version that is onboarded. 

