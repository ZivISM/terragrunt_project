include "root" {
  path = find_in_parent_folders("root.hcl")
} 

terraform {
  source = "../../../tf-modules/cluster"
}

inputs = { 
#######################################################################################
# GENERAL
#######################################################################################
  project            = "ziv-terragrunt"
  env                = "dev"
  region             = "us-east-1"
  tags               = {
    "Project" = "ziv-terragrunt"
    "Environment" = "dev"
    "Region" = "us-east-1"
    "Terragrunt" = "true"
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
    Terragrunt = "true"
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
  fargate_additional_profiles = {}
  karpenter_tag = {
    "karpenter.sh/discovery" = "karpenter"
  }
  karpenter_config = {
    "core" = {
      tainted    = true    # Marks nodes with a taint to prevent regular workloads from scheduling
      core       = true    # Identifies this as a core system component provisioner
      disruption = true    # disruption of these nodes during maintenance
      arc        = false   # Disables AWS Resource Controller integration
      amiFamily  = "AL2023" # Uses Amazon Linux 2023 as the node AMI
      labels = {
        "nodepool" = "core"
      }
      instance_category = {
        operator = "In"
        values   = ["t"]  
      }
      instance_cpu = {
        operator = "In"
        values   = ["4"]  
      }
      instance_hypervisor = {
        operator = "In"
        values   = ["nitro"]
      }
      instance_generation = {
        operator = "Gt"
        values   = ["2"]
      }
      capacity_type = {
        operator = "In"
        values   = ["spot"] # Spot instances / on-demand instances
      }
      instance_family = {
        operator = "In"
        values   = ["t"]
        minValues = 1
      }
      limits = {
        cpu               = "10"
        memory            = "10Gi"
        ephemeral_storage = "10Gi"
      }
    }

    "workers" = {
      tainted    = false
      core       = false
      disruption = true
      arc        = false
      amiFamily  = "AL2023"
      labels = {
        "nodepool" = "workers"
      }
      instance_category = {
        operator = "In"
        values   = ["t"]  
      }
      instance_cpu = {
        operator = "In"
        values   = ["2"]  
      }
      instance_hypervisor = {
        operator = "In"
        values   = ["nitro"]
      }
      instance_generation = {
        operator = "Gt"
        values   = ["2"]
      }
      capacity_type = {
        operator = "In"
        values   = ["spot"]  
      }
      instance_family = {
        operator = "In"
        values   = ["t"]
        minValues = 3
      }
      limits = {
        cpu               = "5"
        memory            = "5Gi"
        ephemeral_storage = "5Gi"
      }
    }    
  }

#######################################################################################
# BLUEPRINTS
#######################################################################################
  enable_aws_load_balancer_controller = true
  enable_metrics_server = true
  enable_kube_prometheus_stack = true
  enable_aws_efs_csi_driver = true
}
