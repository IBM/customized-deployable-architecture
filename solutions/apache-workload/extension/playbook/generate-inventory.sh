#! /bin/sh
fip="${1}"
webserver="${2}"

# create an ansible inventory file and fill in the ip addresses for the jump box and vsi
#
{
echo "[jumpbox_public]"
echo "my-public-bastion ansible_host=${fip}"
echo " "

echo "[webserver_private]"
echo "my-webserver-target ansible_host=${webserver}"
echo " "

echo "[webserver_private:vars]"
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q root@${fip} -o StrictHostKeyChecking=no -o IdentityFile=./keyfile \"'"
echo " "

echo "[all:vars]"
echo "ansible_ssh_private_key_file=./keyfile "
echo " "
} > inventory.ini