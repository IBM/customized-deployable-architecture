#
variable "vault_secrets_app_name" {
    type = string
    description = "The name of the Vault Secrets application containing my secrets."
}

variable "vault_secrets_apikey_secret_name" {
    type = string
    description = "The name of the Vault Secrets secret containing the apikey value."
}

variable "vault_secrets_ssh_private_key_secret_name" {
    type = string
    description = "The name of the Vault Secrets secret containing the ssh_private_key value."
}

variable "vault_secrets_ssh_key_secret_name" {
    type = string
    description = "The name of the Vault Secrets secret containing the ssh_key value."
}