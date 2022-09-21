#####
# Policies - Extract
#####

locals {
  # extract policies from files
  policy_dir             = "config/policies/"
  policy_yaml_file_paths = fileset(path.module, "${local.policy_dir}/**/*.yaml")
  policy_yaml_configs = {
    for file_path in local.policy_yaml_file_paths :
    lookup(yamldecode(file(file_path)).metadata, "name", replace(file_path, "/${local.policy_dir}|.yaml/", "")) => yamldecode(file(file_path))
  }
}

#####
# Policies - Identity
#####

# filter policies for identity
locals {
  identity_policy_configs = { for k, v in local.policy_yaml_configs : k => v if contains(lookup(v.metadata, "accounts", []), "identity") }
}

resource "aws_iam_policy" "identity_policies" {
  for_each = local.identity_policy_configs

  name        = each.key
  path        = "/access/"
  description = lookup(each.value["metadata"], "description", null)
  policy      = jsonencode(each.value["policy"])
}

module "identity_bot_policies" {
  for_each = local.bot_user_configs

  source = "./modules/user-policies"

  user     = aws_iam_user.all[each.key].name
  policies = lookup(each.value, "policies", [])
}

#####
# Policies - Beta
#####

# filter policies for beta
locals {
  beta_policy_configs = { for k, v in local.policy_yaml_configs : k => v if contains(lookup(v.metadata, "accounts", []), "beta") }
}

resource "aws_iam_policy" "beta_policies" {
  for_each = local.beta_policy_configs

  name        = each.key
  path        = "/access/"
  description = lookup(each.value["metadata"], "description", null)
  policy      = jsonencode(each.value["policy"])

  provider = aws.beta_terraform_iamfull
}

#####
# Policies - Prod
#####

# filter policies for prod
locals {
  prod_policy_configs = { for k, v in local.policy_yaml_configs : k => v if contains(lookup(v.metadata, "accounts", []), "prod") }
}

resource "aws_iam_policy" "prod_policies" {
  for_each = local.prod_policy_configs

  name        = each.key
  path        = "/access/"
  description = lookup(each.value["metadata"], "description", null)
  policy      = jsonencode(each.value["policy"])

  provider = aws.prod_terraform_iamfull
}

#####
# Policies - Aggregate Created IAM Policies
#####

locals {
  # Aggregate created IAM policies
  all_policies = merge(
    aws_iam_policy.identity_policies,
    aws_iam_policy.beta_policies,
    aws_iam_policy.prod_policies,
  )
}
