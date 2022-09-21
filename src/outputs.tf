#####
# Sign-In URL
#####

output "signin_url" {
  description = "Sign-in URL for IAM users"
  value       = "https://${aws_iam_account_alias.identity.account_alias}.signin.aws.amazon.com/console"
}

#####
# Users - Outputs
#####

output "users" {
  description = "Each user's ARN & Encrypted Password (if applicable)"
  value = {
    for k, v in aws_iam_user.all :
    k => {
      arn                = v.arn,
      encrypted_password = lookup(aws_iam_user_login_profile.pgp, k, "") == "" ? null : aws_iam_user_login_profile.pgp[k].encrypted_password,
      # groups             = lookup(member_groups, k, null),
    }
  }
}

#####
# Policies - Outputs
#####

output "policies" {
  description = "Each policy's ARN"
  value = {
    for k, v in local.all_policies :
    k => {
      arn = v.arn,
    }
  }
}

#####
# Roles - Outputs
#####

output "roles" {
  description = "Each role's ARN & the URL to assume it"
  value = {
    for k, v in data.aws_arn.all_roles :
    k => {
      arn             = v.arn,
      switch_role_url = format(local.switch_role_url_spec, v["account"], replace(v["resource"], "/^role//", ""), k)
    }
  }
}

# output "switch_role_urls" {
#   description = "URL that auto-fills the required account and role information"
#   value = {
#     for k, v in data.aws_arn.all_roles :
#     k => format(local.switch_role_url_spec, v["account"], replace(v["resource"], "/^role//", ""), k)
#   }
# }

#####
# Groups - Outputs
#####

output "groups" {
  description = "Each group's ARN"
  value = {
    for k, v in aws_iam_group.all :
    k => {
      arn = v.arn,
    }
  }
}
