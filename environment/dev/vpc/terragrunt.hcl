include "root" {
  path = find_in_parent_folders("root.hcl")
} 

terraform {
  source = "../../../tf-modules/vpc"
}

inputs = {
  env                = "dev"
  vpc_cidr           = "10.0.0.0/16"
  project            = "Terragrunt-project"
  region             = "us-east-1"
  num_zones          = 2
  
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false 
  enable_dns_hostnames = true
  enable_dns_support = true


  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery" = "karpenter"
  }

  vpc_tags = {
    status = "Terragrunty"
    environment = "dev"
  }
}
