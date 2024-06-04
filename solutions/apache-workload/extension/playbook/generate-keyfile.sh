#! /bin/sh

# 
# This script creates a file to contain an ssh private key value.  The file will be used as part of 
# an ssh operation by ansible.
#
# The value passed to the script may be in heredoc format (multi-line string).  If it is present 
# the heredoc notation needs to be removed and the file must end with a newline.
#

private_key="${1}"

echo "${private_key}" > keyfile

# echo "${private_key}" > keyfile1.tmp
# # if a line begins with "<<" then remove it
# sed "/^<<-EOF/d" < keyfile1.tmp > keyfile2.tmp
# sed "/^<<EOF/d" < keyfile2.tmp  > keyfile3.tmp
# # if there is a heredoc marker then remove the line
# sed "/^EOF/d" < keyfile3.tmp > keyfile

# rm keyfile1.tmp 2>/dev/null
# rm keyfile2.tmp 2>/dev/null
# rm keyfile3.tmp 2>/dev/null

# file has to have a newline at the end of it so add one back
#echo "" >> keyfile

# ssh keyfile permissions must be 600
chmod 600 keyfile
