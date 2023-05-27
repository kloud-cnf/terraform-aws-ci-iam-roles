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

  # Merge yaml interface inline polices + templated json polices
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

data "aws_iam_openid_connect_provider" "this" {
  url = "https://${local.oidc_provider_domain}"
}

data "aws_iam_policy_document" "trust_policy" {
  for_each = local.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider_domain}:sub"
      values = flatten([for project in each.value.trusted_projects_refs : [
        [for combo in setproduct(project.paths, project.branches) : format("${local.provider_schema[var.platform].subkey}:%s:ref_type:branch:ref:%s", combo[0], combo[1])],
        [for combo in setproduct(project.paths, project.tags) : format("${local.provider_schema[var.platform].subkey}:%s:ref_type:tag:ref:%s", combo[0], combo[1])],
      ]])
    }
  }
}

resource "aws_iam_role" "ci_role" {
  for_each = local.roles

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.trust_policy[each.key].json
}

data "aws_iam_policy_document" "ci_inline_policy" {
  for_each = local.inline_policies

  dynamic "statement" {
    for_each = each.value

    content {
      sid       = statement.value.sid
      actions   = statement.value.actions
      effect    = statement.value.effect
      resources = statement.value.resources
      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "ci_inline_policy" {
  for_each = local.inline_policies

  name   = "base"
  role   = aws_iam_role.ci_role[each.key].id
  policy = data.aws_iam_policy_document.ci_inline_policy[each.key].json
}

data "aws_iam_policy" "managed_policies" {
  for_each = local.managed_policies

  name = each.key
}

resource "aws_iam_role_policy_attachment" "ci_managed_policy" {
  for_each = local.managed_policy_attachments

  role       = aws_iam_role.ci_role[each.value.role_name].name
  policy_arn = data.aws_iam_policy.managed_policies[each.value.policy_name].arn
}
