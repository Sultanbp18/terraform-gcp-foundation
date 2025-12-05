output "service_accounts" {
  description = "Map of created service accounts"
  value = { for k, v in google_service_account.service_accounts : k => {
    email       = v.email
    id          = v.id
    name        = v.name
    unique_id   = v.unique_id
    account_id  = v.account_id
    }
  }
}

output "service_account_emails" {
  description = "Map of service account emails"
  value       = { for k, v in google_service_account.service_accounts : k => v.email }
}

output "service_account_keys" {
  description = "Map of created service account keys (sensitive)"
  value = { for k, v in google_service_account_key.keys : k => {
    name            = v.name
    private_key     = v.private_key
    public_key      = v.public_key
    valid_after     = v.valid_after
    valid_before    = v.valid_before
    }
  }
  sensitive = true
}

output "custom_roles" {
  description = "Map of created custom roles"
  value = { for k, v in google_project_iam_custom_role.custom_roles : k => {
    id          = v.id
    name        = v.name
    role_id     = v.role_id
    title       = v.title
    permissions = v.permissions
    }
  }
}

output "project_iam_bindings" {
  description = "Map of project IAM bindings"
  value = { for k, v in google_project_iam_member.project_bindings : k => {
    role    = v.role
    member  = v.member
    project = v.project
    }
  }
}