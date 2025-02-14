include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../tf-modules/vpc"
}

inputs = {
  env                = "dev"
  vpc_cidr           = "10.0.0.0/16"
  project            = "Terragrunt-project"
  
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
    "${var.karpenter_tag.key}" = "${var.karpenter_tag.value}"
  }
  
  karpenter_tag = {
    key     = "karpenter.sh/nodepool"
    value   = "karpenter"
  }

  vpc_tags = {
    status = "Terragrunty"
    environment = "staging"
  }
}
