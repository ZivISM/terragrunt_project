locals {


###############################################################################
# cluster logging configuration CloudWatch
###############################################################################
  enabled_cluster_logs = ["api", "audit", "controllerManager", "scheduler", "authenticator"]



###############################################################################
# Fargate profile configuration 
###############################################################################
  fargate_profile = var.enable_karpenter ? merge({
    karpenter = {
      selectors = [
        { namespace = "karpenter" }  # Run Karpenter controller in Fargate
      ]
    }
    },
  var.fargate_additional_profiles) : tomap(var.fargate_additional_profiles)



###############################################################################
# AWS IAM to Kubernetes RBAC mapping
###############################################################################
  merged_map_roles = distinct(concat(
    var.enable_karpenter ? [
      # Karpenter Controller Role
      # Allows Karpenter to manage node lifecycle
      {
        rolearn  = module.karpenter[0].iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",  # Required for node registration
          "system:nodes",          # Required for node operation
        ]
      },
      # Karpenter Node IAM Role
      # Used by nodes provisioned by Karpenter
      {
        rolearn  = module.karpenter[0].node_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",  # For initial node setup
          "system:nodes",          # For ongoing node operations
        ]
      },
      # Cluster Administrator Role
      # Grants full cluster access to current AWS account
      {
        rolearn  = data.aws_caller_identity.current.arn
        username = "clusteradmin"
        groups   = ["system:masters"]  # Kubernetes super-admin group
      }
    ] : [
      # Default Admin Role (when Karpenter is disabled)
      # Ensures cluster remains accessible
      {
        rolearn  = data.aws_caller_identity.current.arn
        username = "clusteradmin"
        groups   = ["system:masters"]
      }
    ],
    # Additional Custom Roles
    # Allows for extra IAM role mappings defined in variables
    var.map_roles
  ))
}

# Get current AWS account information
data "aws_caller_identity" "current" {}

