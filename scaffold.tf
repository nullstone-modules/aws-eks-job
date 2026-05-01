module "scaffold" {
  source = "registry.terraform.io/nullstone-modules/eks-appscaffold/aws"

  region                          = local.region
  account_id                      = local.account_id
  partition                       = local.partition
  app_name                        = local.app_name
  block_ref                       = local.block_ref
  resource_suffix                 = random_string.resource_suffix.result
  tags                            = local.tags
  image_url                       = var.image_url
  cluster_name                    = local.cluster_name
  cluster_arn                     = local.cluster_arn
  kubernetes_namespace            = local.kubernetes_namespace
  kubernetes_service_account_name = local.app_name
  use_irsa                        = local.use_irsa
  cluster_oidc_issuer             = local.cluster_oidc_issuer
  cluster_openid_provider_arn     = local.cluster_openid_provider_arn
  op_assumer_arns                 = [local.ns_agent_user_arn]
}

locals {
  image_url = module.scaffold.repository_url
}
