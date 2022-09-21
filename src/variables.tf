variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "account_ids" {
  description = "Map of account names to account IDs"
  type        = map(string)
  default     = {}
}

variable "identity_alias" {
  description = "An alias for the identity account which is used to generate a login URL (must be unique among the entirety of AWS)"
  type        = string
}
