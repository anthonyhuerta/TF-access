#####
# Users - Extract & Transform
#####

locals {
  # extract users from files
  user_file_paths = fileset(path.module, "config/users/**/*.yaml")
  human_user_configs = {
    for x in flatten([
      for file_path in local.user_file_paths : [
        for user, obj in try(yamldecode(file(file_path)).humans, {}) : {
          (user) = obj
        }
      ]
    ]) : keys(x)[0] => values(x)[0]
  }
  # string => string
  human_user_paths = { for k, v in local.human_user_configs : k => lookup(v, "path", "") }

  bot_user_configs = {
    for x in flatten([
      for file_path in local.user_file_paths : [
        for user, obj in try(yamldecode(file(file_path)).bots, {}) : {
          (user) = obj
        }
      ]
    ]) : keys(x)[0] => values(x)[0]
  }
  # string => string
  bot_user_paths = { for k, v in local.bot_user_configs : k => lookup(v, "path", "") }

  all_user_configs = merge(local.human_user_configs, local.bot_user_configs)
  all_user_paths   = merge(local.human_user_paths, local.bot_user_paths)
}

#####
# Users - Create Users
#####

resource "aws_iam_user" "all" {
  for_each = local.all_user_configs

  name          = each.key
  path          = "/access/${local.all_user_paths[each.key]}"
  force_destroy = true

  tags = {
    "Name"          = each.key
    "User:FullName" = lookup(each.value, "full_name", null)
    "User:Email"    = lookup(each.value, "email", null)
  }
}

resource "aws_iam_user_login_profile" "pgp" {
  for_each = local.human_user_configs

  user = aws_iam_user.all[each.key].name
  # Generated using `gpg --export 6FBAFC5FBAA37F05BF623953C9AF5704077CB8D6 | base64 > config/keys/womply-infra.pkr`
  pgp_key = file("${path.root}/config/keys/womply-infra.pkr")

  password_length         = 20
  password_reset_required = false

  lifecycle {
    ignore_changes = [pgp_key]
  }

  depends_on = [
    aws_iam_user.all,
  ]
}

#####
# Users - Self-Manage Credentials & MFA
#####

resource "aws_iam_user_policy_attachment" "self_manage_credentials" {
  for_each = local.human_user_configs

  user       = aws_iam_user.all[each.key].name
  policy_arn = aws_iam_policy.identity_policies["self_manage_credentials"].arn

  depends_on = [
    aws_iam_user.all,
  ]
}
