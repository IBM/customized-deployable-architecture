#! /bin/bash

# run the ibmcloud cli installer
curl -sL https://ibm.biz/idt-installer | bash

# run the ibmcloud cli and install needed plugins
ibmcloud plugin install catalogs-management
ibmcloud plugin install schematics

# list whats installed into the log
ibmcloud plugin list