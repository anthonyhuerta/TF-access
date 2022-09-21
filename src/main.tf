# womply - access

#####
# Remote State Lookup
#####

data "terraform_remote_state" "master_org" {
  backend = "remote"
  config = {
    organization = "womply"
    workspaces = {
      # TFE bug causes false validation errors unless name includes a variable
      name = var.region != "" ? "master-org" : "master-org"
    }
  }
}

data "terraform_remote_state" "apps_beta" {
  backend = "remote"
  config = {
    organization = "womply"
    workspaces = {
      name = "beta-apps"
    }
  }
}

data "terraform_remote_state" "apps_prod" {
  backend = "remote"
  config = {
    organization = "womply"
    workspaces = {
      name = "prod-apps"
    }
  }
}

#####
# Local Vars - Shared
#####

locals {
  account_ids = var.account_ids == {} ? var.account_ids : {
    beta       = data.terraform_remote_state.master_org.outputs.beta_account_id
    identity   = data.terraform_remote_state.master_org.outputs.identity_account_id
    prod       = data.terraform_remote_state.master_org.outputs.prod_account_id
    sandbox    = "639015794711"
    legacy     = "985433556411"
    fundrocket = "754841671700"
  }
  account_names = {
    for name, id in local.account_ids :
    id => name
  }

  # Roles limited to managing IAM in other accounts
  terraform_iamfull_roles = {
    beta     = data.terraform_remote_state.master_org.outputs.beta_terraform_iamfull_role_arn
    identity = data.terraform_remote_state.master_org.outputs.identity_terraform_iamfull_role_arn
    prod     = data.terraform_remote_state.master_org.outputs.prod_terraform_iamfull_role_arn
  }

  switch_role_url_spec = "https://signin.aws.amazon.com/switchrole?account=%s&roleName=%s&displayName=%s"

  beta_apps_microservice_queues = data.terraform_remote_state.apps_beta.outputs.microservice_queues
  beta_apps_soa_topics          = data.terraform_remote_state.apps_beta.outputs.topics
  prod_apps_microservice_queues = data.terraform_remote_state.apps_prod.outputs.microservice_queues
  prod_apps_soa_topics          = data.terraform_remote_state.apps_prod.outputs.topics

  common_tags = {
    "ManagedBy"            = "terraform"
    "Terraform:RootModule" = "access"
  }
}

#####
# Local Vars - Identity
#####

locals {
  identity_tags = merge(
    local.common_tags,
    {
      "AccountID"   = local.account_ids["identity"]
      "AccountName" = "identity"
    },
  )
}

#####
# Local Vars - Beta
#####

locals {
  beta_tags = merge(
    local.common_tags,
    {
      "AccountID"   = local.account_ids["beta"]
      "AccountName" = "beta"
    },
  )
}

#####
# Local Vars - Prod
#####

locals {
  prod_tags = merge(
    local.common_tags,
    {
      "AccountID"   = local.account_ids["prod"]
      "AccountName" = "prod"
    },
  )
}

#####
# Sign-In URL
#####

resource "aws_iam_account_alias" "identity" {
  account_alias = var.identity_alias
}
