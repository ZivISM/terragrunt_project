###############################################################################
# EKS Module
###############################################################################
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  create                                   = var.eks_enabled
  version                                  = "20.8.4"
  cluster_name                             = "${var.project}-${var.env}"
  cluster_version                          = var.k8s_version
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = slice(module.vpc.private_subnets, 0, var.num_zones)
  enable_irsa                              = true
  eks_managed_node_groups                  = var.enable_karpenter ? {} : var.eks_managed_node_groups
  enable_cluster_creator_admin_permissions = true
  tags                                     = var.tags
  node_security_group_tags = {
    "${var.karpenter_tag.key}" = "${var.karpenter_tag.value}"
  }

  fargate_profiles = local.fargate_profile


  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }


    pod-access = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  cluster_security_group_additional_rules = {
    ingress_vpn = {
      description = "Acces cluster via vpc"
      protocol    = "TCP"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["${var.vpc_cidr}"]
    }
  }

  cloudwatch_log_group_retention_in_days = "7"
  cluster_enabled_log_types              = local.enabled_cluster_logs
  depends_on                             = [
                                            module.vpc, 
                                          ]

  }

###############################################################################
# IAM
###############################################################################

module "allow_eks_acceess_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"
  name  = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "eks:DescribeCluster",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
    depends_on                             = [
                                            module.eks, 
                                          ]
}

###############################################################################
# EKS-AUTH
###############################################################################
module "eks_auth" {
  source = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.8.4"
  aws_auth_roles = local.merged_map_roles
}

###############################################################################
# EKS Admin IAM Role
###############################################################################
module "eks_admins_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_acceess_iam_policy.arn]
  
  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]

}

###############################################################################
# EKS Admins IAM Group
###############################################################################
module "allow_assume_eks_admins_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"
  name  = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "sts:AssumeRole",
        ]
        Effect = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

###############################################################################
# EKS Admins IAM Group
###############################################################################
module "eks_admins_iam_group" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.48.0"
  
  name                              = "eks-admins"
  attach_iam_self_management_policy = false
  create_group                      = true
  # group_users                       = [module.eks_iam_user.iam_user_name]
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}

###############################################################################
# EKS Admins IAM Group Membership
###############################################################################
resource "aws_iam_user_group_membership" "localadmin_to_eks_admins" {
  user = "localadmin"
  groups = [
    module.eks_admins_iam_group.group_name
  ]
}