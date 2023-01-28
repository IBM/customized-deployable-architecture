# Application Extension for Custom Secure Infrastructure on VPC

This example shows how an extension could be added on to an existing Custom Secure Infrastructure landscape by deploying an additional 
Virtual Server into the Workload VPC.  The virtual server is initialized and an application is installed.  In this case the appplication
is *Apache web server*.

Ansible is used here to illustrate application provisioning.  There are additional methods such as using a cloud init script during the 
initialization of the virtual server for example which could be suited for simple scenarios.  Ansible is easier to debug which is jsut one of
its many benefits.


