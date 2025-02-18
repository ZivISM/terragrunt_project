###############################################################################
# Karpenter Controller Policy
###############################################################################
resource "aws_iam_policy" "karpenter_controller_policy" {
  count       = var.enable_karpenter ? 1 : 0
  name        = "karpenter_controller_policy_${var.project}-${var.env}-cluster"
  description = "Policy to grant IAM role access to create Service-Linked Role for EC2 Spot Instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot*"
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = "spot.amazonaws.com"
          }
        }
      }
    ]
  })
    depends_on = [ 
    module.eks,
  ]
}

###############################################################################
# Karpenter Module
###############################################################################
module "karpenter" {
  count  = var.enable_karpenter ? 1 : 0
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  version                         = "20.8.4"
  cluster_name                    = module.eks.cluster_name
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  # Attach additional IAM policies to the Karpenter node IAM role
  create_access_entry = false
  iam_role_policies = {
    "ec2spotfleetrole" = "${aws_iam_policy.karpenter_controller_policy[0].arn}"
  }
  node_iam_role_additional_policies = {
    "AmazonEBSCSIDriverPolicy" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  tags = var.tags
  depends_on = [ 
    aws_iam_policy.karpenter_controller_policy
  ]
}



###############################################################################
# Karpenter Helm + Data Resources
###############################################################################
resource "helm_release" "karpenter" {
  count               = var.enable_karpenter ? 1 : 0
  namespace           = "karpenter"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.0"
  depends_on          = [module.karpenter]
  wait                = true
  create_namespace    = true
  values = [
    <<-EOT
    replicas: 1
    dnsPolicy: Default 
    serviceAccount:
      annotations:
       eks.amazonaws.com/role-arn: ${module.karpenter[0].iam_role_arn}
    controller:
      env:
       - name: AWS_REGION
         value: "${var.region}"
      resources:
        requests:
          cpu: "2"
          memory: "2Gi"
        limits:
          cpu: "8" 
          memory: "4Gi"
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter[0].queue_name}
      featureGates:
        spotToSpotConsolidation: "true"
    tolerations:
      - key: 'eks.amazonaws.com/compute-type'
        operator: Equal
        value: fargate
        effect: "NoSchedule"
    EOT
  ]
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.forKarpenter
}

###############################################################################
# Karpenter Manifests
###############################################################################
resource "helm_release" "karpenter-manifests" {
  for_each        = var.karpenter_config
  name            = each.key
  chart           = "${path.module}/karpenter-manifests"
  wait            = true
  depends_on      = [ helm_release.karpenter ]
  force_update    = true
  cleanup_on_fail = true
  set {
    name  = "nodePool.tainted"
    value = each.value.tainted != null ? each.value.tainted : false
  }
  set {
    name  = "nodePool.disruption"
    value = each.value.disruption != null ? each.value.disruption : true
  }
  set {
    name  = "metadataOptions.httpEndpoint"
    value = "enabled"
  }
  values = [<<EOT
  ec2nc:
    karpenter_role: "${module.karpenter[0].node_iam_role_name}"
    amiFamily: "${each.value.amiFamily}"
    karpenter_tag: "${var.karpenter_tag.key}"
    karpenter_value: "${var.karpenter_tag.value}"
    ephemeral_storage: "${each.value.limits.ephemeral_storage}"
  nodePool:
    instance_category: 
      operator: ${each.value.instance_category.operator}
      values: ${jsonencode(each.value.instance_category.values)}
    instance_cpu: 
      operator: ${each.value.instance_cpu.operator}
      values: ${jsonencode(each.value.instance_cpu.values)}
    instance_hypervisor: 
      operator: ${each.value.instance_hypervisor.operator}
      values: ${jsonencode(each.value.instance_hypervisor.values)}
    instance_generation: 
      operator: ${each.value.instance_generation.operator}
      values: ${jsonencode(each.value.instance_generation.values)}
    capacity_type: 
      operator: ${each.value.capacity_type.operator}
      values: ${jsonencode(each.value.capacity_type.values)}
    %{if each.value.instance_family != null}
    instance_family: 
      operator: ${each.value.instance_family.operator}
      values: ${jsonencode(each.value.instance_family.values)}
    %{endif}
    cpu: "${each.value.limits.cpu}"
    memory: "${each.value.limits.memory}"
    labels: ${jsonencode(each.value.labels)}
    EOT
  ]
}