variable "platform" {
  type        = string
  description = "Target CI platform for module instantiation for which the `var.roles` will configure a trust relationship for"
  validation {
    condition     = contains(["github", "gitlab"], var.platform)
    error_message = "${var.platform} platform not supported. Must be `github` or `gitlab`"
  }
}

variable "roles" {
  description = "IAM Roles to provision with permissions and trusted projects paths & refs"
  type = set(object({
    name_suffix = string
    trusted_projects_refs = set(object({
      paths    = set(string)
      branches = optional(set(string), [])
      tags     = optional(set(string), [])
    }))
    managed_policies = optional(set(string), [])
    policy_statements = optional(set(object({
      sid       = optional(string)
      effect    = string
      actions   = set(string)
      resources = set(string)
      conditions = optional(set(object({
        test     = string
        variable = string
        values   = set(string)
      })), [])
    })), [])
    templated_policy_statements = optional(set(object({
      template = string
      values   = optional(map(set(string)), {})
    })), [])
  }))

  validation {
    condition     = alltrue(flatten([for role in var.roles : [for project in role.trusted_projects_refs : length(project.branches) + length(project.tags) > 0]]))
    error_message = "For each trusted project associated with a role, it is mandatory to specify at least one of branch or tags. Wildcards in the form of * are acceptable in either of these fields."
  }
}
