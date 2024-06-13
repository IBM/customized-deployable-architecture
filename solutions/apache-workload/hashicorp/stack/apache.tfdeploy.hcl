deployment "test" {
    variables = {
        prefix      = "kb-test"
        region      = "us-south"
        vault_secrets_app_name = ""
        vault_secrets_apikey_secret_name = ""
        vault_secrets_ssh_private_key_secret_name = ""
        vault_secrets_ssh_key_secret_name = ""
    }
}