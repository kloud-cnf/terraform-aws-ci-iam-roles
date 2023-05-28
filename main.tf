resource "aws_iam_role_policy" "ci_inline_policy" {
  for_each = local.inline_policies

  name   = "base"
  role   = aws_iam_role.ci_role[each.key].id
  policy = data.aws_iam_policy_document.ci_inline_policy[each.key].json
}

resource "aws_iam_role" "ci_role" {
  for_each = local.roles

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.trust_policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "ci_managed_policy" {
  for_each = local.managed_policy_attachments

  role       = aws_iam_role.ci_role[each.value.role_name].name
  policy_arn = data.aws_iam_policy.managed_policies[each.value.policy_name].arn
}
