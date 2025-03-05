## hashicorp/stack

An implementation of the Custom Apach stack on the Hashicorp cloud using Terraform stacks.

Prerequisites:
Must have a Terraform Cloud account with access to the private preview of Terraform stacks and an HCP account
with HCP Vault Secrets containing the secrets needed.

- Configure HCP Vault Secrets authentication.  [See this link](https://github.com/hashicorp-guides/github-via-vault-secrets-stack#usage)
    - login to HCP
    - navigate to organization dashboard
    - navigate to the organization to be used
    - navigate to Access control (IAM)
    - navigate to Service principals
    - create service principal with Admin access for the organization

- HCP Vault Secrets must contain 3 secrets:
    - apikey - used to configure the IBM Cloud Terraform provider with authentication credential
    - ssh_private_key - an ssh private key that pairs with the ssh_key 
    - ssh_key - an ssh public key that pairs with the ssh_private_key