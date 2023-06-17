locals {
  roles            = { for role in var.roles : "${var.platform}-ci-${role.name_suffix}" => role }
  managed_policies = toset(flatten([for _, role in local.roles : role.managed_policies]))
  managed_policy_attachments = { for attachment in flatten([for role_name, role in local.roles : [
    for policy in role.managed_policies : {
      key         = join("_", [role_name, policy])
      role_name   = role_name
      policy_name = policy
    }]]) : attachment.key => attachment
  }

  template_file_defaults = {
    aws_account_id = data.aws_caller_identity.current.account_id
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
    [for _, template_values in role.templated_policy_statements : [for statement in jsondecode(templatefile("${path.module}/templates/policies/${template_values.template}.json.tmpl", merge(
      local.template_file_defaults,
      try(template_values.values, {})
      ))) :
      {
        sid       = lookup(statement, "Sid", null)
        effect    = title(statement.Effect)
        actions   = flatten([statement.Action])
        resources = flatten([statement.Resource])
        conditions = flatten([for test, condition in lookup(statement, "Condition", {}) : [for k, v in condition : {
          test     = test
          variable = k
          values   = tolist([v])
        }]])
    }]]
  ]) if length(role.policy_statements) + length(role.templated_policy_statements) > 0 }

  // TODO support custom domains via inputs
  oidc_provider_domain = var.platform == "github" ? "token.actions.githubusercontent.com" : "gitlab.com"

  // For each role, format trusted refrences for supported platform
  platform_formatted_trusted_refs = {
    // Github -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    // repo:<orgName/repoName>:ref:refs/heads/<branchName>  -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-a-specific-branch
    // repo:<orgName/repoName>:ref:refs/tags/<tagName>      -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-a-specific-tag
    // repo:<orgName/repoName>:pull_request                 -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-pull_request-events
    github = {
      for k, v in local.roles : k => flatten([for project in v.trusted_projects_refs : [
        [for path in project.paths : format("repo:%s:pull_request", path) if project.pull_request],
        [for combo in setproduct(project.paths, project.branches) : format("repo:%s:ref:refs/heads/%s", combo[0], combo[1])],
        [for combo in setproduct(project.paths, project.tags) : format("repo:%s:ref:refs/tags/%s", combo[0], combo[1])],
      ]])
    }

    // Gitlab -> https://docs.gitlab.com/ee/ci/cloud_services/index.html#configure-a-conditional-role-with-oidc-claims
    // project_path:{group}/{project}:ref_type:{type}:ref:{branch_name||tag_name}
    // project_path:mygroup/myproject:ref_type:branch:ref:main
    // project_path:mygroup/myproject:ref_type:tag:ref:v1.0.0
    gitlab = {
      for k, v in local.roles : k => flatten([for project in v.trusted_projects_refs : [
        [for combo in setproduct(project.paths, project.branches) : format("project_path:%s:ref_type:branch:ref:%s", combo[0], combo[1])],
        [for combo in setproduct(project.paths, project.tags) : format("project_path:%s:ref_type:tag:ref:%s", combo[0], combo[1])],
      ]])
    }
  }
}
