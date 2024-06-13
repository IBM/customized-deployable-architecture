#
data "hcp_vault_secrets_secret" "apikey" {
    # vault - specify the secret name for apikey
    app_name    = var.vault_secrets_app_name
    secret_name = var.vault_secrets_apikey_secret_name
}

data "hcp_vault_secrets_secret" "ssh_private_key" {
    # vault - specify the secret name for ssh_private_key
    app_name    = var.vault_secrets_app_name
    secret_name = var.vault_secrets_ssh_private_key_secret_name
}

data "hcp_vault_secrets_secret" "ssh_key" {
    # vault - specify the secret name for ssh_key
    app_name       = var.vault_secrets_app_name
    secret_name    = var.vault_secrets_ssh_key_secret_name
}