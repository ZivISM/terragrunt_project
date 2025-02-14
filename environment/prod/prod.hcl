include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

##################################################
# LOCALS
##################################################
locals {
  environment = "prod"
}

##################################################
# S3 BUCKET + DYNAMODB TABLE
##################################################
generate "s3_bucket" {
  path      = "s3_bucket.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.project}-${local.environment}-terraform-state"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.project}-${local.environment}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
EOF
}