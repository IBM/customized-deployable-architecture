#! /bin/sh

# 
# This script creates a file to contain an ssh private key value.  The file will be used as part of 
# an ssh operation by ansible.
#
# The value passed to the script is expected to be in heredoc format (multi-line string).  The heredoc
# notation needs to be removed and the file must end with a newline.
#

private_key="${1}"

# The private key value was wrapped within heredoc notation to facilate passing a multi-line
# input value to terraform.  It is of the form:
#   <<-EOF
#   actual private key value
#   EOF
# Need to strip the heredoc notation and create a file with just the key value followed 
# by a new line character.  The file must have the required permissions set of 600.

# remove the first heredoc notation on line 1
echo "${private_key}" | sed 's/<<-EOF//' > keyfile1.tmp

# remove the last two lines of the file to remove the heredoc "EOF" marker
sed '$d' < keyfile1.tmp > keyfile2.tmp
sed '$d' < keyfile2.tmp > keyfile3.tmp

# remove the newline characater at the beginning of the file that is left over from heredoc notation
tail -c +2 keyfile3.tmp > keyfile

# file has to have a newline at the end of it so add one back
echo "" >> keyfile

# ssh keyfile permissions must be 600
chmod 600 keyfile

# cleanup 
rm keyfile1.tmp keyfile2.tmp keyfile3.tmp