#! /bin/sh
fip="${1}"
webserver="${2}"
private_key="${3}"

# step 0 - debug by dumping input values
echo "-----begin generate script-------"
echo "fip=${1}"
echo "webserver=${2}"
echo "private_key=${3}"
echo "-----end debug output------------"

# step 1 - create a file with the ssh private key value so that it may be used below with cli
#   - remove leading heredoc marker
#   - remove last line which is another heredoc marker
#   - remove a leading newline character
#   - key file permissions must be 600
echo "${private_key}" | sed 's/<<-EOF//' > keyfile1.tmp

cat keyfile1.tmp | sed '$d' > keyfile2.tmp
cat keyfile2.tmp | sed '$d' > keyfile3.tmp

# tail -r keyfile1.tmp > keyfile2.tmp
# tail -n +2 keyfile2.tmp > keyfile3.tmp
# tail -r keyfile3.tmp > keyfile4.tmp

tail -c +2 keyfile3.tmp > keyfile

chmod 600 keyfile

# step 2 - create an ansible inventory file and fill in the ip addresses for the jump box and vsi
#
{
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
} > inventory-test.txt