variable "additional_tags" {
  description = "A map of additional tags to add to all new policies"
  type        = map(string)
  default     = {}
}

variable "policies" {
  description = "List non-template file paths relative to the directory `config/policies/iam-permissions/` that will be used to create IAM policies"
  type        = list(string)
  default     = []
}

variable "user" {
  description = "The user to create the policies for"
  type        = string
}
