#! /bin/sh

# 
# This script creates a file to contain an ssh private key value.  The file will be used as part of 
# an ssh operation by ansible.
#
# The value passed to the script is expected to be in heredoc format (multi-line string).  The heredoc
# notation needs to be removed and the file must end with a newline.
#

private_key="${1}"

echo "${private_key}" > keyfile

# ssh keyfile permissions must be 600
chmod 600 keyfile
