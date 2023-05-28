output "role_names" {
  value       = [for k, v in local.roles : aws_iam_role.ci_role[k].name]
  description = "Names of the created IAM roles."
}

output "role_arns" {
  value       = [for k, v in local.roles : aws_iam_role.ci_role[k].arn]
  description = "ARNs (Amazon Resource Names) of the created IAM roles."
}

output "role_inline_polices" {
  value       = local.inline_policies
  description = "ARNs of the inline policies attached to the IAM roles."
}

output "role_managed_polices" {
  value       = { for k, v in local.managed_policy_attachments : v.role_name => aws_iam_role_policy_attachment.ci_managed_policy[k].policy_arn... }
  description = "Attachment(s) of managed policies attached to the IAM roles."
}
