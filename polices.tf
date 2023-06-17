resource "aws_iam_policy" "name" {
  name        = "ci-permission-boundary"
  path        = "/ci"
  policy      = data.aws_iam_policy_document.ci_permission_boundary.json
  description = "IAM policy for CI runners with restricted permissions to create and manage AWS resources."
}
