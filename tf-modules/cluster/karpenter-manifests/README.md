# karpenter-manifests

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ec2nc.amiFamily | string | `""` |  |
| ec2nc.annotations."helm.sh/hook" | string | `"pre-install"` |  |
| ec2nc.karpenter_role | string | `""` |  |
| ec2nc.karpenter_tag | string | `""` |  |
| ec2nc.karpenter_value | string | `""` |  |
| nodePool.capacity_type.operator | string | `""` |  |
| nodePool.capacity_type.values[0] | string | `""` |  |
| nodePool.cpu | string | `""` |  |
| nodePool.instance_category.operator | string | `""` |  |
| nodePool.instance_category.values | list | `[]` |  |
| nodePool.instance_cpu.operator | string | `""` |  |
| nodePool.instance_cpu.values | list | `[]` |  |
| nodePool.instance_generation.operator | string | `""` |  |
| nodePool.instance_generation.values[0] | string | `""` |  |
| nodePool.instance_hypervisor.operator | string | `""` |  |
| nodePool.instance_hypervisor.values[0] | string | `""` |  |
| nodePool.memory | string | `nil` |  |

