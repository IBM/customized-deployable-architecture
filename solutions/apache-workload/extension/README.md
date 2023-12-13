# Application Extension for Custom Secure Infrastructure on VPC

This example deployable architecture shows how an extension could be applied to an existing Custom Secure Infrastructure.  This 
deployable architecture is an extension deployable architecture which means it has a dependency on pre-existing resources.  In 
this example, the resources are provided by the Custom Secure Infrastructure deployable architecture also provided in this 
repository.  This example utilizes an IBM Cloud Project.

This deployable architecture:
- provisions a virtual server within an existing virtual private cloud in a secure subnet.  The VPC also has provisioned within it a jumpbox with a public IP address.
- provides Ansible playbooks and scripts to drive the installation of Apache onto the virtual server.

Note, the jumpbox is required to access the virtual server.  This is done with ssh.

To be used as described here, this extension must be onboarded to an IBM Cloud Catalog that has been configured with an IBM Cloud Project.  In 
this example, the catalog has been configured with a target account context that has been created with a Project and an IBM Cloud API key.  For 
additional details, see the [IBM documentation](https://cloud.ibm.com/docs/account?topic=account-catalog-cross-validation#target-project-id).

## How it works

- step 1: the terraform template provisions a virtual server within an existing virtual private cloud.
- step 2: once the terraform deploy completes, the Project executes the post deploy operation defined by an Ansible playbook contained in the scripts subdirectory.
- step 3: the playbook is a bootstrap script/playbook that:
    - creates an Ansible inventory file customized with the IP addresses of jumpbox and the newly provisioned virtual server.  The jumpbox IP is a public address and the virtual server has a private IP address.
    - creates a ssh keyfile containg the private ssh key that is already associated to the public ssh key that was used to deploy the jumpbox.  The virtual server is automatically deployed with this same public ssh key.
    - Ansible is executed and uses the inventory file, key file and a standard playbook to perform the installation of Apache on the virtual server.

Here is an example of the inventory file created:

```
[jumpbox_public]
my-public-bastion ansible_host=150.240.72.50
[webserver_private]
my-webserver-target ansible_host=10.10.10.5
[webserver_private:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q root@150.240.72.50 -o StrictHostKeyChecking=no -o IdentityFile=./keyfile \"'
[all:vars]
ansible_ssh_private_key_file=./keyfile 
```

The playbook to install Apache is this 

```
 - name: Playbook to install Apache
   hosts: webserver_private
   remote_user: root
   tasks:
    - name: Ansible apt install apache2
      ansible.builtin.apt:
        name: apache2
        state: present
        update_cache: true
```

The playbook is very basic.  Since an Ubuntu image was installed on the virtual server, the playbook uses the ubuntu apt command to perform the application install.  This playbook could easily be adapted to work with other platforms and install different applications.

Sample output from the Ansible execute step is show here:

```
2023/12/12 16:20:27 ansible-playbook run | TASK [debug] *******************************************************************
 2023/12/12 16:20:27 ansible-playbook run | ok: [localhost] => {
 2023/12/12 16:20:27 ansible-playbook run |     "playbook_out": {
 2023/12/12 16:20:27 ansible-playbook run |         "changed": true,
 2023/12/12 16:20:27 ansible-playbook run |         "cmd": [
 2023/12/12 16:20:27 ansible-playbook run |             "ansible-playbook",
 2023/12/12 16:20:27 ansible-playbook run |             "-i",
 2023/12/12 16:20:27 ansible-playbook run |             "inventory.ini",
 2023/12/12 16:20:27 ansible-playbook run |             "../playbook/install-apache-on-webservers.yaml"
 2023/12/12 16:20:27 ansible-playbook run |         ],
 2023/12/12 16:20:27 ansible-playbook run |         "delta": "0:00:38.999717",
 2023/12/12 16:20:27 ansible-playbook run |         "end": "2023-12-12 16:20:26.992865",
 2023/12/12 16:20:27 ansible-playbook run |         "failed": false,
 2023/12/12 16:20:27 ansible-playbook run |         "rc": 0,
 2023/12/12 16:20:27 ansible-playbook run |         "start": "2023-12-12 16:19:47.993148",
 2023/12/12 16:20:27 ansible-playbook run |         "stderr": "",
 2023/12/12 16:20:27 ansible-playbook run |         "stderr_lines": [],
 2023/12/12 16:20:27 ansible-playbook run |         "stdout": "\nPLAY [Playbook to install Apache] **********************************************\n\nTASK [Gathering Facts] *********************************************************\nok: [my-webserver-target]\n\nTASK [Ansible apt install apache2] *********************************************\nchanged: [my-webserver-target]\n\nPLAY RECAP *********************************************************************\nmy-webserver-target        : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   ",
 2023/12/12 16:20:27 ansible-playbook run |         "stdout_lines": [
 2023/12/12 16:20:27 ansible-playbook run |             "",
 2023/12/12 16:20:27 ansible-playbook run |             "PLAY [Playbook to install Apache] **********************************************",
 2023/12/12 16:20:27 ansible-playbook run |             "",
 2023/12/12 16:20:27 ansible-playbook run |             "TASK [Gathering Facts] *********************************************************",
 2023/12/12 16:20:27 ansible-playbook run |             "ok: [my-webserver-target]",
 2023/12/12 16:20:27 ansible-playbook run |             "",
 2023/12/12 16:20:27 ansible-playbook run |             "TASK [Ansible apt install apache2] *********************************************",
 2023/12/12 16:20:27 ansible-playbook run |             "changed: [my-webserver-target]",
 2023/12/12 16:20:27 ansible-playbook run |             "",
 2023/12/12 16:20:27 ansible-playbook run |             "PLAY RECAP *********************************************************************",
 2023/12/12 16:20:27 ansible-playbook run |             "my-webserver-target        : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   "
 2023/12/12 16:20:27 ansible-playbook run |         ]
 2023/12/12 16:20:27 ansible-playbook run |     }
 2023/12/12 16:20:27 ansible-playbook run | }
 2023/12/12 16:20:27 ansible-playbook run | 
 2023/12/12 16:20:27 ansible-playbook run | PLAY RECAP *********************************************************************
 2023/12/12 16:20:27 ansible-playbook run | localhost                  : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
 2023/12/12 16:20:27 ansible-playbook run | 
 2023/12/12 16:20:27 Command finished successfully.
 2023/12/12 16:20:31 [1m[32mDone with the job action[39m[0m
```
