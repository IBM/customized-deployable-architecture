This Readme is to provide details regarding the git Action in this repo.  The action is used to automate the onboarind, validating and publishing to 
a catalog a version of the three offerings within this repo.  Additionally, the versions are scanned using the IBM CRA scanning functions.

The action is initiated everytime a new release is created within the repo.  Since the repo contains three offerings, each release contains a new 
version of each of the three offerings.  They are all onboarded to the catalog in separate steps of the action.

The action requires the configuration of a secret that has a value of an IBM Cloud account's API key that has sufficient IAM permissions to provision 
resources.  See the Git documentation to configure the secret.  The secret should be named IBMCLOUD_API_KEY.  The remaining settings are defined 
within the workflow definition file - publish-pipeline.yml.

The steps within the workflow are the following.

1.  Git checkout - get the contents of the release onto the worker machine provisioned to run this workflow.
2.  Install and setup IBMCLOUD Cli - perform set up needed for the remaining steps by installing the ibmcloud cli and needed plugins.
3.  Upload, validate, scan and publish custom-deployable-arch - deploys resources for a custom architecture.
4.  Upload, validate, scan and publish custom-apache extension - deploys an Apache server onto the custom architecture from step 3.
5.  Cleanup deployed resources - destroys all resources created in steps 3 and 4.
6.  Upload, validate, scan and publish custom-apache fullstack - deploys custom architecture and Apache server using a Schematics blueprint.
7.  Cleanup deployed resources - destroys all resources created in step 6.

Note: the base assumption with this workflow is that each of the three offerings have already been initially created within the given catalog.  The workflow
only onboards new versions that have resulted from creating a release.