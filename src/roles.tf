#####
# Roles - Extract & Transform
#####

locals {
  # extract role data from files
  role_file_paths = fileset(path.module, "config/roles/**/*.yaml")
  role_configs = {
    for x in flatten([
      for file_path in local.role_file_paths : [
        for role, obj in yamldecode(file(file_path)).user_roles : {
          (role) = obj
        }
      ]
    ]) : keys(x)[0] => values(x)[0]
  }

  # intermediate steps to work around the limitations of "for_each"
  role_policies = { for k, v in local.role_configs : k => v.policies if lookup(v, "policies", []) != [] }
  role_policy_pairs = flatten([
    for role, policies in local.role_policies : [
      for policy in policies : {
        account = local.role_configs[role].account
        role    = role
        policy  = policy
      }
    ]
  ])

  # string => map(string)
  role_policy_joins = {
    for obj in local.role_policy_pairs :
    replace("${obj.role}${obj.policy}", "/arn:aws:iam::|([[:punct:]]+)/", "_") => obj
  }
}

#####
# Roles - Identity
#####

# filter roles for identity
locals {
  identity_role_configs      = { for k, v in local.role_configs : k => v if lookup(v, "account", "") == "identity" }
  identity_role_policy_joins = { for k, v in local.role_policy_joins : k => v if lookup(v, "account", "") == "identity" }
}

# create identity roles
resource "aws_iam_role" "identity_roles" {
  for_each = local.identity_role_configs

  name                  = each.key
  path                  = "/access/${lookup(each.value, "path", "")}"
  description           = lookup(each.value, "description", "")
  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.trust_identity_with_mfa.json

  tags = merge(
    local.identity_tags,
    {
      "Name" = each.key,
    },
  )
}

# attach policies to identity roles
resource "aws_iam_role_policy_attachment" "identity_role_policies" {
  for_each = local.identity_role_policy_joins

  role       = each.value["role"]
  policy_arn = each.value["policy"]

  depends_on = [
    aws_iam_policy.identity_policies,
    aws_iam_role.identity_roles,
  ]
}

#####
# Roles - Beta
#####

# filter roles for beta
locals {
  beta_role_configs      = { for k, v in local.role_configs : k => v if lookup(v, "account", "") == "beta" }
  beta_role_policy_joins = { for k, v in local.role_policy_joins : k => v if lookup(v, "account", "") == "beta" }
}

# create beta roles
resource "aws_iam_role" "beta_roles" {
  for_each = local.beta_role_configs

  name                  = each.key
  path                  = "/access/${lookup(each.value, "path", "")}"
  description           = lookup(each.value, "description", "")
  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.trust_identity_with_mfa.json

  tags = merge(
    local.beta_tags,
    {
      "Name" = each.key,
    },
  )

  provider = aws.beta_terraform_iamfull
}

# attach policies to beta roles
resource "aws_iam_role_policy_attachment" "beta_role_policies" {
  for_each = local.beta_role_policy_joins

  role       = each.value["role"]
  policy_arn = each.value["policy"]

  depends_on = [
    aws_iam_policy.beta_policies,
    aws_iam_role.beta_roles,
  ]

  provider = aws.beta_terraform_iamfull
}

#####
# Roles - Prod
#####

# filter roles for prod
locals {
  prod_role_configs      = { for k, v in local.role_configs : k => v if lookup(v, "account", "") == "prod" }
  prod_role_policy_joins = { for k, v in local.role_policy_joins : k => v if lookup(v, "account", "") == "prod" }
}

# create prod roles
resource "aws_iam_role" "prod_roles" {
  for_each = local.prod_role_configs

  name                  = each.key
  path                  = "/access/${lookup(each.value, "path", "")}"
  description           = lookup(each.value, "description", "")
  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.trust_identity_with_mfa.json

  tags = merge(
    local.prod_tags,
    {
      "Name" = each.key,
    },
  )

  provider = aws.prod_terraform_iamfull
}

# attach policies to prod roles
resource "aws_iam_role_policy_attachment" "prod_role_policies" {
  for_each = local.prod_role_policy_joins

  role       = each.value["role"]
  policy_arn = each.value["policy"]

  depends_on = [
    aws_iam_policy.prod_policies,
    aws_iam_role.prod_roles,
  ]

  provider = aws.prod_terraform_iamfull
}

#####
# Roles - Assume Role
#####

locals {
  # aggregate created IAM roles
  all_roles = merge(
    aws_iam_role.identity_roles,
    aws_iam_role.beta_roles,
    aws_iam_role.prod_roles,
  )
}

# grants identity entities permission to assume the role only if MFA is enabled
data "aws_iam_policy_document" "trust_identity_with_mfa" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_ids["identity"]}:root"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = [86400]
    }
  }
}

data "aws_arn" "all_roles" {
  for_each = local.role_configs
  arn      = local.all_roles[each.key].arn
}

data "aws_iam_policy_document" "assume_roles" {
  for_each = data.aws_arn.all_roles

  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      each.value.arn
    ]
  }
}

resource "aws_iam_policy" "assume_role" {
  for_each = data.aws_arn.all_roles

  name        = "assume-${each.key}"
  path        = "/access/"
  description = "Assume role ${each.key} in the account ${local.account_names[each.value.account]} (${each.value.account})"

  policy = data.aws_iam_policy_document.assume_roles[each.key].json
}
