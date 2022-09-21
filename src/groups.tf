#####
# Groups - Extract & Transform
#####

locals {
  # extract group data from files
  group_file_paths = fileset(path.module, "config/groups/**/*.yaml")
  group_configs = {
    for x in flatten([
      for file_path in local.group_file_paths : [
        for group, obj in yamldecode(file(file_path)).user_groups : {
          (group) = obj
        }
      ]
    ]) : keys(x)[0] => values(x)[0]
  }

  # intermediate steps to work around the limitations of "for_each"
  group_roles = { for k, v in local.group_configs : k => v.roles if lookup(v, "roles", []) != [] }
  group_role_pairs = flatten([
    for group, roles in local.group_roles : [
      for role in roles : {
        group = group
        role  = role
      }
    ]
  ])

  # string => map(string)
  group_role_joins = {
    for obj in local.group_role_pairs :
    replace("${obj.group}_${obj.role}", "/[[:punct:]]/", "_") => obj
  }

  # string => list(string)
  group_members = { for k, v in local.group_configs : k => v.members if lookup(v, "members", []) != [] }
  member_groups = transpose(local.group_members)
}

#####
# Groups - Create Resources
#####

# create groups
resource "aws_iam_group" "all" {
  for_each = local.group_configs

  name = each.key
  path = "/access/${lookup(each.value, "path", "")}"
}

# attach assume-role policies to groups
resource "aws_iam_group_policy_attachment" "assume_role" {
  for_each = local.group_role_joins

  group      = each.value["group"]
  policy_arn = aws_iam_policy.assume_role[each.value["role"]].arn

  depends_on = [
    aws_iam_group.all,
    aws_iam_policy.assume_role,
  ]
}

# add users to groups
resource "aws_iam_user_group_membership" "all" {
  for_each = local.member_groups

  user   = each.key
  groups = each.value

  depends_on = [
    aws_iam_group.all,
    aws_iam_user.all,
  ]
}
