# secrets

This module takes a list of secret names and creates them in AWS secrets manager. This is useful when you need to do a double loop.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.35 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_user_policy_attachment.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | A map of additional tags to add to all new policies | `map(string)` | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | List non-template file paths relative to the directory `config/policies/iam-permissions/` that will be used to create IAM policies | `list(string)` | `[]` | no |
| <a name="input_user"></a> [user](#input\_user) | The user to create the policies for | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policies"></a> [policies](#output\_policies) | Policies created by the module |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
