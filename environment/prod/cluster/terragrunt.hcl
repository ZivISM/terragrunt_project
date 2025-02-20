include "root" {
  path = find_in_parent_folders("root.hcl")
} 

terraform {
  source = "../../../tf-modules/cluster"
}

#############################################################
# KUBERNETES PROVIDERS
#############################################################
generate "kubernetes_providers" {
  path      = "kubernetes_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
EOF
}


inputs = { 
#######################################################################################
# GENERAL
#######################################################################################
  project            = "ziv-terragrunt"
  env                = "prod"
  region             = "us-east-1"
  tags               = {
    "Project" = "ziv-terragrunt"
    "Environment" = "prod"
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
  domain_name = "ziv-terragrunt.testing"

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery" = "karpenter"
  }

  vpc_tags = {
    Terragrunt = "true"
    environment = "prod"
  }

#######################################################################################
# CLUSTER
#######################################################################################
  eks_enabled = true
  k8s_version = "1.27"
  enable_karpenter = true

  eks_managed_node_groups = null

  map_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/localadmin"
      username = "localadmin"
      groups   = ["system:masters"]
    }
  ]
  map_accounts = ["123456789012"] # Main AWS account ID
  map_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/eks-admin"
      username = "eks-admin" 
      groups   = ["system:masters"]
    }
  ]

#######################################################################################
# KARPENTER
#######################################################################################
  karpenter_enabled = true
  fargate_additional_profiles = {}
  karpenter_tag = {
    key   = "karpenter.sh/discovery"
    value = "karpenter"
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


