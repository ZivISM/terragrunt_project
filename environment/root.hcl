# Root terragrunt.hcl
locals {
  environment = basename(dirname(get_terragrunt_dir()))
  project     = "ziv-terragrunt"
}

##############################################################################
# REMOTE STATE
##############################################################################
remote_state {
  backend = "s3"

  config = {
    bucket         = "${local.project}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "${local.project}-${local.environment}-terraform-locks"
  }
}

##############################################################################
# BACKEND
##############################################################################
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.project}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "${local.project}-${local.environment}-terraform-locks"
    force_destroy  = true
  }
}
EOF
}

##############################################################################
# PROVIDERS 
##############################################################################
generate "providers" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.18.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
      configuration_aliases = [aws.forKarpenter]
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "forKarpenter"
}
EOF
}

##############################################################################
# AWS PROVIDERS
##############################################################################
# generate "aws_providers" {
#   path      = "aws_providers.tf"
#   if_exists = "overwrite_terragrunt"
#   contents = <<EOF
# provider "aws" {
#   region = "us-east-1"
# }
# EOF
# }

