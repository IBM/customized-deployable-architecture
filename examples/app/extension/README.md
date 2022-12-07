# Application Extension for Custom Secure Infrastructure on VPC

This example shows how an extension could be added on to an existing Custom Secure Infrastructure landscape by deploying an additional 
Virtual Server into the Workload VPC.  The virtual server is initialized and configured as an *Apache web server*.

Once this is deployed, the Apache server may be tested by:
1. ssh to the jump box using the exposed floating IP address.  This is from the deployment of the Custom Secure Infrastructure.
2. determine the IP address of the Apache virtual server.  This may be done from the Cloud Console by navigating to the `VPC Infrastructure` menu and then 
selecting `Virtual Server Instances`.  Locate the virtual server labeled `apache-webserver` and copy it's IP address.
3. from the jump box, request the default home page from the Apache server for example `curl 10.x.x.x:80`
