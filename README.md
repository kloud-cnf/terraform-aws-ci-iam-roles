# terraform-aws-ci-iam-roles

> Terraform module for creating CI roles with OIDC trust 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [Description](#description)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Role Creation for Specified Platform](#role-creation-for-specified-platform)
  - [GitHub example](#github-example)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---
## Description

This Terraform module focuses on creating IAM roles specifically for CI platforms, with support currently limited to [GitHub](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) and [GitLab](https://docs.gitlab.com/ee/integration/openid_connect_provider.html).

The module implements a trust relationship between CI platforms and AWS using [OpenID Connect (OIDC)](https://openid.net/connect/). Access is determined based on project paths and git references, allowing for granular control over permissions.

To define fine-grained permissions for roles, the module provides the flexibility to specify policy_statements and templated_policy_statements. This enables you to tailor access policies according to your specific requirements.

Additionally, the module supports attaching managed policy ARNs to the roles, allowing you to leverage existing policies for CI workflows.

By utilizing this Terraform module, you can easily create IAM roles with customized permissions for CI platforms, establish trust relationships via OIDC, and enforce security measures based on project paths and git refs.

---

## Prerequisites

Before using this Terraform module to create IAM roles for CI platforms, please ensure the following prerequisites are met:

1. Identity Provider Setup: The target AWS account must have the corresponding identity provider (IdP) configured for the desired CI platform (GitLab or GitHub). The IdP should be properly set up and connected to the AWS account to establish the trust relationship with the CI platform.

2. IAM Role Provisioner: To enable the creation of child roles for CI, an IAM role provisioner is required. You can use the module available at [kloud-cnf/terraform-aws-ci-role-provisioner](https://github.com/kloud-cnf/terraform-aws-ci-role-provisioner). This module facilitates the provisioning of the parent IAM role and supports the necessary configuration for role delegation and trust relationships.

Ensure that both the identity provider is set up and the IAM role provisioner module is in place before utilizing this Terraform module for creating CI roles. These prerequisites ensure the proper establishment of trust and enable the seamless creation of IAM roles for CI workflows in AWS.

---

## Usage

### Role Creation for Specified Platform

Please note that the IAM roles defined in the var.roles variable will be created only for the platform specified in var.platform.

To create the same roles for both platforms, you can instantiate the module twice, once for each platform. Please be aware that this may require refactoring in the future if a more streamlined approach is developed.

Consider storing a configuration repository, such as `<platform>-aws-ci-roles`, on both GitHub and GitLab. This can provide a centralized location for managing and versioning the role configurations specific to each platform.

### GitHub example
```hcl
terraform {
  source = "git::https://github.com/kloud-cnf/terraform-aws-ci-iam-roles//?ref=v0.1.0"
}

inputs = {
  platform = "github"
  roles = [
    {
      name_suffix = "admin"
      trusted_projects_refs = [
        { 
          paths = ["<my_org>/*"]
          branches = ["*"]
          tags = ["*"]
        }
      ]
      managed_policies = ["AdministratorAccess"]
    },
    {
      name_suffix = "s3-admin"
      trusted_projects_refs = [
        { 
          paths = ["<my_org>/cdn-assets"]
          branches = ["*"]
          tags = ["*"]
        }
      ]
      managed_policies = ["AmazonS3FullAccess"]
    },
    {
      name_suffix = "s3-readonly"
      trusted_projects_refs = [
        { 
          paths = ["<my_org>/s3-asset-ui"]
          branches = ["*"]
          tags = ["*"]
        }
      ]
      templated_policy_statements = [
        {
          template = "s3-readonly"
          values = {
            paths: ["<my_org>_assets/*"]
          }
        }
      ]
    }
  ]
}
```

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ci_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ci_inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ci_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy.managed_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.ci_inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ci_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_platform"></a> [platform](#input\_platform) | Target CI platform for module instantiation for which the `var.roles` will configure a trust relationship for | `string` | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | IAM Roles to provision with permissions and trusted projects paths & refs | <pre>set(object({<br>    name_suffix = string<br>    trusted_projects_refs = set(object({<br>      paths        = set(string)<br>      branches     = optional(set(string), [])<br>      tags         = optional(set(string), [])<br>      pull_request = optional(bool, true) # Allow role to be assumed on PR event, defaults to true, only needed for GitHub<br>    }))<br>    managed_policies = optional(set(string), [])<br>    policy_statements = optional(set(object({<br>      sid       = optional(string)<br>      effect    = string<br>      actions   = set(string)<br>      resources = set(string)<br>      conditions = optional(set(object({<br>        test     = string<br>        variable = string<br>        values   = set(string)<br>      })), [])<br>    })), [])<br>    templated_policy_statements = optional(set(object({<br>      template = string<br>      values   = optional(map(set(string)), {})<br>    })), [])<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | ARNs (Amazon Resource Names) of the created IAM roles. |
| <a name="output_role_inline_polices"></a> [role\_inline\_polices](#output\_role\_inline\_polices) | ARNs of the inline policies attached to the IAM roles. |
| <a name="output_role_managed_polices"></a> [role\_managed\_polices](#output\_role\_managed\_polices) | Attachment(s) of managed policies attached to the IAM roles. |
| <a name="output_role_names"></a> [role\_names](#output\_role\_names) | Names of the created IAM roles. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
