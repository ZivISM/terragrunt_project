include "root" {
  path = find_in_parent_folders("root.hcl")
}

##################################################
# LOCALS
##################################################
locals {
  environment = "prod"
}

