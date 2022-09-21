#####
# Identity - Security
#####

resource "aws_iam_account_password_policy" "identity" {
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 170
  minimum_password_length        = 16
  password_reuse_prevention      = 6
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
}


#####
# Beta - Security
#####

# Limit password persistence in case someone tries to add a console user to this account
resource "aws_iam_account_password_policy" "beta" {
  allow_users_to_change_password = false
  hard_expiry                    = true
  max_password_age               = 1
  minimum_password_length        = 36
  password_reuse_prevention      = 24

  provider = aws.beta_terraform_iamfull
}


#####
# Prod - Security
#####

# Limit password persistence in case someone tries to add a console user to this account
resource "aws_iam_account_password_policy" "prod" {
  allow_users_to_change_password = false
  hard_expiry                    = true
  max_password_age               = 1
  minimum_password_length        = 36
  password_reuse_prevention      = 24

  provider = aws.prod_terraform_iamfull
}
