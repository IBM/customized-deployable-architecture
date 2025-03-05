# need this because we are getting a secret from HCP Vault Secrets
identity_token "vault_secrets" {
    audience = ["<Set to your HCP IAM assume-role audience>"]
}

deployment "test" {
    variables = {
        prefix      = "kb-test"
        region      = "us-south"
        #
        vault_secrets_app_name = "IBMCloud"
        vault_secrets_apikey_secret_name = "apikey"
        vault_secrets_ssh_private_key_secret_name = "ssh_private_key"
        vault_secrets_ssh_key_secret_name = "ssh_key"
        workload_idp_name         = "<Set to your fully delimited HCP IAM workload identity provider. This is the same as the hcp_iam_workload_identity_provider.idp.resource_name attribute in the HCP Terraform provider.>"
        identity_token_file       = identity_token.vault_secrets.jwt_filename
    }
}