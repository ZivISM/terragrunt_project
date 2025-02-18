include "root" {
  path = find_in_parent_folders("root.hcl")
} 

terraform {
  source = "../../../tf-modules/*"
}

inputs = { 
#######################################################################################
# GENERAL
#######################################################################################
  project            = "Terragrunt-project"
  env                = "dev"
  region             = "us-east-1"
  tags               = {
    "Project" = "Terragrunt-project"
    "Environment" = "dev"
    "Region" = "us-east-1"
  }

#######################################################################################
# NETWORK
#######################################################################################
  vpc_cidr           = "10.0.0.0/16"
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

#######################################################################################
# CLUSTER
#######################################################################################
  eks_enabled = true
  k8s_version = "1.27"
  enable_karpenter = true

  eks_managed_node_groups = null

  map_users = null
  map_accounts = null
  map_roles = null

#######################################################################################
# KARPENTER
#######################################################################################
  karpenter_enabled = true
  karpenter_node_selector = {
    "karpenter.sh/discovery" = "karpenter"
  }

#######################################################################################
# BLUEPRINTS
#######################################################################################
  enable_aws_load_balancer_controller = true
  enable_metrics_server = true
  enable_kube_prometheus_stack = true
  enable_aws_efs_csi_driver = true
}
