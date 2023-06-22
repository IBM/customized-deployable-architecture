# Extending a deployable architecture

In this set of tutorials, we will show how to extend a deployable architecture, specifically the Custom SLZ deployable architecture already highlighted in previous tutorials.

The Custom SLZ deployable architecture is a good example of a deployable architecture that would be extended in someway since it creates a landscape with necessary resources from 
which to build a bigger solution.  For this scenario, the extension will be that we are deploying a workload into the landscape that was deployed by Custom SLZ.  The 
workload chosen is an Apache webserver which will be installed using Ansible.  So to do this the extension will deploy a virtual server into the virtual private cloud, created 
by Custom SLZ, and then on that virtual server it will deploy the Apache webserver application.

When extending a deployable architecture, we develop another deployable architecture.  Deployable architectures that are designed to extend come in two types, extension and 
fullstack.  Extension types have at least one dependency on another deployable architecture and cannot be deployed unless that dependency has already been deployed.  Fullstack 
types have a dependency, however, it is written in such a way that it deploys the dependency and the extension itself all at the same time.  The end result is the same regardless 
of which type, fullstack or extension, was used to deploy.

## Tutorials
This repo contains three tutorials that step through how to write terraform to extend a deployable architecture.  Its important to examine each of the tutorials below in 
the order given to properly build on the concepts presented within them.

-  [Apache workload extension](./1-extension/) - a deployable architecture of type extension that is dependent on Custom SLZ.  Deploys an Apache workload.
-  [Apache workload extension with a bonus](./2-extension-bonus/) - same deployable architecture extension but with the introduction of additional terraform techniques.
-  [Apache extension as a fullstack](./3-fullstack/) - a deployable architecture of type fullstack.  It deploys Custom SLZ and the extension.

