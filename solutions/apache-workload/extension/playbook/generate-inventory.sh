#! /bin/sh
fip=$1
webserver=$2
private_key=$3

echo "${private_key}" > keyfile
chmod 600 keyfile

echo "[jumpbox_public]"
echo "my-public-bastion ansible_host=${fip}"
echo " "

echo "[webserver_private]"
echo "my-webserver-target ansible_host=${webserver}"
echo " "

echo "[webserver_private:vars]"
echo "ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -q root@${fip} -o IdentityFile=./keyfile \"'"
echo " "

echo "[all:vars]"
echo "ansible_ssh_private_key_file=./keyfile " 
echo " "