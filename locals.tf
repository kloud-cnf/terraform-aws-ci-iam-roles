locals {
  roles            = { for role in var.roles : "${var.platform}-ci-${role.name_suffix}" => role }
  managed_policies = toset(flatten([for _, role in local.roles : role.managed_policies]))
  managed_policy_attachments = { for combo in flatten([for role_name, role in local.roles : [
    for policy in role.managed_policies : {
      key         = join("_", [role_name, policy])
      role_name   = role_name
      policy_name = policy
    }]]) : combo.key => combo
  }

  # Merge interface inline polices + templated json polices
  inline_policies = { for role_name, role in local.roles : role_name => flatten([
    [for statement in role.policy_statements : {
      sid        = lookup(statement, "sid", null)
      effect     = title(statement.effect)
      actions    = flatten(statement.actions)
      resources  = flatten(statement.resources)
      conditions = flatten(statement.conditions)
    }],
    [for _, template_values in role.templated_policy_statements : [for statement in jsondecode(templatefile("${path.module}/templates/policies/${template_values.template}.json.tmpl", template_values.values)) :
      {
        sid       = lookup(statement, "Sid", null)
        effect    = title(statement.Effect)
        actions   = flatten([statement.Action])
        resources = flatten([statement.Resource])
        conditions = flatten([for test, condition in lookup(statement, "Condition", {}) : [for k, v in condition : {
          test     = test
          variable = k
          values   = v
        }]])
    }]]
  ]) if length(role.policy_statements) + length(role.templated_policy_statements) > 0 }

  // TODO support custom domains via inputs
  oidc_provider_domain = var.platform == "github" ? "token.actions.githubusercontent.com" : "gitlab.com"

  provider_schema = {
    github = {
      subkey = "repo" # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
    }
    gitlab = {
      subkey = "project_path" # https://docs.gitlab.com/ee/ci/cloud_services/aws/#configure-a-role-and-trust
    }
  }
}