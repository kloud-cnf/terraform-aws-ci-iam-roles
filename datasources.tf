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

data "aws_iam_policy" "managed_policies" {
  for_each = local.managed_policies

  name = each.key
}

data "aws_iam_openid_connect_provider" "this" {
  url = "https://${local.oidc_provider_domain}"
}

data "aws_iam_policy_document" "trust_policy" {
  for_each = local.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    sid     = "TrustPolicy"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider_domain}:sub"
      values   = local.platform_formatted_trusted_refs[var.platform][each.key]
    }
  }
}