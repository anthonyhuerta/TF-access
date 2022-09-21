resource "aws_iam_policy" "policies" {
  for_each = toset(var.policies)

  # Name from after "/" (if present) but before "."
  name        = regex("^([a-zA-Z/]+\\/)?([^./]+)\\..+$", each.key)[1]
  description = "Policy for IAM user ${var.user}"
  policy      = file("${path.root}/config/policies/iam-permissions/${each.key}")

  tags = merge(var.additional_tags, {
    Name = regex("^([a-zA-Z/]+\\/)?([^./]+)\\..+$", each.key)[1]
  })
}

resource "aws_iam_user_policy_attachment" "policies" {
  for_each = aws_iam_policy.policies

  user       = var.user
  policy_arn = each.value.arn
}
