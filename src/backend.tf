#####
# TFE Workspace
#####

# Variables may not be used here
terraform {
  backend "remote" {
    organization = "womply"

    workspaces {
      name = "identity-access"
    }
  }
}

#####
# Providers
#####

# identity
provider "aws" {
  assume_role {
    role_arn = local.terraform_iamfull_roles["identity"]
  }

  region = var.region
}

# beta
provider "aws" {
  alias = "beta_terraform_iamfull"

  assume_role {
    role_arn = local.terraform_iamfull_roles["beta"]
  }

  region = var.region
}

# prod
provider "aws" {
  alias = "prod_terraform_iamfull"

  assume_role {
    role_arn = local.terraform_iamfull_roles["prod"]
  }

  region = var.region
}

# dev - Needed only while replacing `dev` with `beta` and can be removed in following commit
provider "aws" {
  alias = "dev_terraform_iamfull"

  assume_role {
    role_arn = local.terraform_iamfull_roles["beta"]
  }

  region = var.region
}
