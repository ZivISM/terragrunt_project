# Root terragrunt.hcl
locals {
  environment = path_relative_to_include()
  project     = "zivoosh-testing-terragrunt"
}

##################################################
# REMOTE STATE
##################################################
remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "${local.project}-${local.environment}-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

##################################################
# PROVIDER
##################################################
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = 
  <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
} 

##################################################
# VERSIONS
##################################################
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = 
  <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
EOF
}