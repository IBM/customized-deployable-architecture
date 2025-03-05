#
output "ssh_key" {
    # TODO: Stacks fail to serialize a sensitive value, so we temporarily nonsensitive() the value for
    # now. Without, it will fail with ".token: value has marks, so it cannot be serialized"
    value = nonsensitive(data.hcp_vault_secrets_secret.apikey.secret_value)
}

output "ssh_private_key" {
    # TODO: Stacks fail to serialize a sensitive value, so we temporarily nonsensitive() the value for
    # now. Without, it will fail with ".token: value has marks, so it cannot be serialized"
    value = nonsensitive(data.hcp_vault_secrets_secret.ssh_private_key.secret_value)
}

output "apikey" {
    # TODO: Stacks fail to serialize a sensitive value, so we temporarily nonsensitive() the value for
    # now. Without, it will fail with ".token: value has marks, so it cannot be serialized"
    value = nonsensitive(data.hcp_vault_secrets_secret.ssh_key.secret_value)
}