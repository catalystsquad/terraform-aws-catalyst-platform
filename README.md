# terraform-aws-catalyst-platform 

This module provisions the Catalyst Platform in AWS. The Catalyst Platform is a
simple end-to-end implementation of Kubernetes in AWS, so that you can get to
what matters most as fast as possible, deploying your code to deliver value. It
includes deployment of:

* An AWS VPC with private and public subnets with appropriate tagging required to operate EKS.
* An EKS cluster with default node groups.
* Management of the `aws-auth` configmap for authorization via AWS IAM into the cluster.
* IAM dependencies for the [cluster autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler).
* S3 and IAM dependencies for operating [Velero](https://velero.io/), [Cortex](https://cortexmetrics.io/), and [Loki](https://grafana.com/oss/loki/) in AWS EKS via IRSA.


## Example Implementations

### Basic

The most basic implementation requires only specifying names and availability
zone configurations:
```terraform
provider "aws" {
  region = "us-east-1"
}

module "platform" {
  source = "github.com/catalystsquad/terraform-aws-catalyst-platform"

  vpc_name = "dev"
  vpc_cidr = "10.1.0.0/16"

  availability_zones = [
    {
      az_name             = "us-east-1a"
      private_subnet_cidr = "10.1.0.0/18"
      public_subnet_cidr  = "10.1.128.0/23"
    },
    {
      az_name             = "us-east-1b"
      private_subnet_cidr = "10.1.64.0/18"
      public_subnet_cidr  = "10.1.130.0/23"
    }
  ]

  eks_cluster_name = "dev"
}
```

### aws-auth configmap management

For management of the AWS auth configmap, a kubernetes provider is required and
must depend on the output of the EKS cluster:


```terraform
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  # overwrite config_path to ensure existing kubeconfig does not get used
  config_path = ""

  # build kube config based on output of platform module to ensure that it
  # speaks to the new cluster when creating the aws-auth configmap
  host                   = module.platform.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.platform.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks", "get-token", "--cluster-name", module.platform.eks_cluster_id,
      # Any additional aws provider configuration should be specified via
      # command line args or environment variables, so that the kubernetes
      # provider can retrieve a token via the AWS CLI. This approach requires
      # the AWS CLI to be installed locally.
      "--region", "us-east-1",
      # "--profile", "my-profile-name", 
    ]
  }
}

module "platform" {
  source = "github.com/catalystsquad/terraform-aws-catalyst-platform"

  vpc_name = "dev"
  vpc_cidr = "10.1.0.0/16"

  availability_zones = [
    {
      az_name             = "us-east-1a"
      private_subnet_cidr = "10.1.0.0/18"
      public_subnet_cidr  = "10.1.128.0/23"
    },
    {
      az_name             = "us-east-1b"
      private_subnet_cidr = "10.1.64.0/18"
      public_subnet_cidr  = "10.1.130.0/23"
    }
  ]

  eks_cluster_name          = "dev"
  manage_aws_auth_configmap = true
  aws_auth_sso_roles = [
    {
      sso_role_name = "admin"
      username      = "admin"
      groups        = ["system:masters"]
    }
  ]
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | n/a | `string` | n/a | yes |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | n/a | <pre>list(object({<br>    az_name             = string<br>    private_subnet_cidr = string<br>    public_subnet_cidr  = string<br>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_roles"></a> [aws\_auth\_roles](#input\_aws\_auth\_roles) | extra roles to add to the mapRoles field in the aws\_auth configmap, for granting access via IAM roles | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_sso_roles"></a> [aws\_auth\_sso\_roles](#input\_aws\_auth\_sso\_roles) | extra SSO roles to add to the mapRoles field. Auto discovers SSO role ARNs based on regex. | <pre>list(object({<br>    sso_role_name = string<br>    username      = string<br>    groups        = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_users"></a> [aws\_auth\_users](#input\_aws\_auth\_users) | extra users to add to the mapUsers field in the aws\_auth configmap, for granting access via IAM users | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_cluster_autoscaler_namespace"></a> [cluster\_autoscaler\_namespace](#input\_cluster\_autoscaler\_namespace) | n/a | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_service_account_name"></a> [cluster\_autoscaler\_service\_account\_name](#input\_cluster\_autoscaler\_service\_account\_name) | n/a | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cortex_namespace"></a> [cortex\_namespace](#input\_cortex\_namespace) | n/a | `string` | `"cortex"` | no |
| <a name="input_cortex_service_account_name"></a> [cortex\_service\_account\_name](#input\_cortex\_service\_account\_name) | n/a | `string` | `"cortex"` | no |
| <a name="input_eks_cluster_enabled_log_types"></a> [eks\_cluster\_enabled\_log\_types](#input\_eks\_cluster\_enabled\_log\_types) | n/a | `list(string)` | `[]` | no |
| <a name="input_eks_cluster_endpoint_private_access"></a> [eks\_cluster\_endpoint\_private\_access](#input\_eks\_cluster\_endpoint\_private\_access) | n/a | `bool` | `false` | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | n/a | `bool` | `true` | no |
| <a name="input_eks_cluster_endpoint_public_access_cidrs"></a> [eks\_cluster\_endpoint\_public\_access\_cidrs](#input\_eks\_cluster\_endpoint\_public\_access\_cidrs) | n/a | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | n/a | `string` | `"1.22"` | no |
| <a name="input_eks_default_node_groups_initial_desired_size"></a> [eks\_default\_node\_groups\_initial\_desired\_size](#input\_eks\_default\_node\_groups\_initial\_desired\_size) | n/a | `number` | `1` | no |
| <a name="input_eks_default_node_groups_instance_types"></a> [eks\_default\_node\_groups\_instance\_types](#input\_eks\_default\_node\_groups\_instance\_types) | n/a | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_eks_default_node_groups_max_size"></a> [eks\_default\_node\_groups\_max\_size](#input\_eks\_default\_node\_groups\_max\_size) | n/a | `number` | `3` | no |
| <a name="input_eks_default_node_groups_min_size"></a> [eks\_default\_node\_groups\_min\_size](#input\_eks\_default\_node\_groups\_min\_size) | n/a | `number` | `1` | no |
| <a name="input_eks_default_node_groups_version"></a> [eks\_default\_node\_groups\_version](#input\_eks\_default\_node\_groups\_version) | Kubernetes version of the EKS cluster's default node group, allows for upgrading the kubernetes control plane first, then upgrading the node groups separately afterwards. Defaults to the specified eks\_cluster\_version variable. | `string` | `""` | no |
| <a name="input_enable_cortex_dependencies"></a> [enable\_cortex\_dependencies](#input\_enable\_cortex\_dependencies) | n/a | `bool` | `false` | no |
| <a name="input_enable_eks_default_node_groups"></a> [enable\_eks\_default\_node\_groups](#input\_enable\_eks\_default\_node\_groups) | enables creation of a default set of node groups, one per availability zone defined by the availability\_zones variable | `bool` | `true` | no |
| <a name="input_enable_eks_subnet_tags"></a> [enable\_eks\_subnet\_tags](#input\_enable\_eks\_subnet\_tags) | n/a | `bool` | `true` | no |
| <a name="input_enable_loki_dependencies"></a> [enable\_loki\_dependencies](#input\_enable\_loki\_dependencies) | n/a | `bool` | `false` | no |
| <a name="input_enable_velero_dependencies"></a> [enable\_velero\_dependencies](#input\_enable\_velero\_dependencies) | n/a | `bool` | `true` | no |
| <a name="input_loki_namespace"></a> [loki\_namespace](#input\_loki\_namespace) | n/a | `string` | `"loki"` | no |
| <a name="input_loki_service_account_name"></a> [loki\_service\_account\_name](#input\_loki\_service\_account\_name) | n/a | `string` | `"loki"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Whether to manage the aws-auth configmap. Requires configuration of a Kubernetes provider. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_velero_namespace"></a> [velero\_namespace](#input\_velero\_namespace) | n/a | `string` | `"velero"` | no |
| <a name="input_velero_service_account_name"></a> [velero\_service\_account\_name](#input\_velero\_service\_account\_name) | n/a | `string` | `"velero"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | n/a | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_autoscaler_irsa_role_arn"></a> [cluster\_autoscaler\_irsa\_role\_arn](#output\_cluster\_autoscaler\_irsa\_role\_arn) | n/a |
| <a name="output_cortex_irsa_role_arn"></a> [cortex\_irsa\_role\_arn](#output\_cortex\_irsa\_role\_arn) | n/a |
| <a name="output_cortex_s3_bucket_id"></a> [cortex\_s3\_bucket\_id](#output\_cortex\_s3\_bucket\_id) | n/a |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | n/a |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | n/a |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | n/a |
| <a name="output_loki_irsa_role_arn"></a> [loki\_irsa\_role\_arn](#output\_loki\_irsa\_role\_arn) | n/a |
| <a name="output_loki_s3_bucket_id"></a> [loki\_s3\_bucket\_id](#output\_loki\_s3\_bucket\_id) | n/a |
| <a name="output_velero_irsa_role_arn"></a> [velero\_irsa\_role\_arn](#output\_velero\_irsa\_role\_arn) | n/a |
| <a name="output_velero_s3_bucket_id"></a> [velero\_s3\_bucket\_id](#output\_velero\_s3\_bucket\_id) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.irsa_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.default_node_group_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private-ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public-igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.cortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.cortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cluster_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_group_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.sso_auto_discover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [tls_certificate.irsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler_irsa_role"></a> [cluster\_autoscaler\_irsa\_role](#module\_cluster\_autoscaler\_irsa\_role) | ./modules/eks-irsa-role | n/a |
| <a name="module_cortex_irsa_role"></a> [cortex\_irsa\_role](#module\_cortex\_irsa\_role) | ./modules/eks-irsa-role | n/a |
| <a name="module_loki_irsa_role"></a> [loki\_irsa\_role](#module\_loki\_irsa\_role) | ./modules/eks-irsa-role | n/a |
| <a name="module_velero_irsa_role"></a> [velero\_irsa\_role](#module\_velero\_irsa\_role) | ./modules/eks-irsa-role | n/a |
<!-- END_TF_DOCS -->