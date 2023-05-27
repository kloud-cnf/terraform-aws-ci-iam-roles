variable "platform" {
 type =  string
 description = "Target CI platform for which the `var.roles` will configure a trust relationship for"

 validation {
   condition = contains(["github", "gitlab"], var.platform)
   error_message = "${var.platform} platform not supported. Must be `github` or `gitlab`"
 }
}

variable "roles" {
  description = "IAM Roles to provision, with permissions and trusted projects paths & refs"
  type = list(object({
    name_suffix = string
    trusted_projects_refs = list(object({
      paths    = set(string)
      branches = optional(set(string), [])
      tags     = optional(set(string), [])
    }))
    managed_policies = optional(set(string), [])
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = set(string)
      resources = set(string)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = set(string)
      })), [])
    })), [])
    templated_policy_statements = optional(list(object({
      template = string
      values   = optional(map(list(string)), {})
    })), [])
  }))

  validation {
    condition     = alltrue(flatten([for role in var.roles : [for project in role.trusted_projects_refs : length(project.branches) + length(project.tags) > 0]]))
    error_message = "At least one of `branches` or `tags` must be specified for every trusted project for a role."
  }
}
