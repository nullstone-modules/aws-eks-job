resource "aws_secretsmanager_secret" "app_secret" {
  for_each = local.managed_secret_keys

  name_prefix             = "${local.block_name}/${each.value}/"
  tags                    = local.tags
  kms_key_id              = module.scaffold.kms_alias_arn
  recovery_window_in_days = 0 // force delete so that re-adding the secret doesn't cause issues

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  for_each = local.managed_secret_keys

  secret_id     = aws_secretsmanager_secret.app_secret[each.value].id
  secret_string = local.managed_secret_values[each.value]

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  app_secret_store_name = "${local.app_name}-secrets"

  // Captured here so workload templates can reference the name without a direct
  // index into the count = 0/1 SecretProviderClass resource (which Terraform
  // would still evaluate inside ternaries even when has_secrets is false).
  spc_name = try(kubernetes_manifest.secret_provider_class[0].manifest.metadata.name, "")
}

// SecretProviderClass tells the CSI driver which Secrets Manager secrets to fetch
// and syncs them into a K8s Secret (local.app_secret_store_name) so they can be
// referenced as env vars via secretKeyRef in the job pod spec.
//
// Important: the K8s Secret only materializes (and stays in sync) when a pod that
// mounts this SecretProviderClass via the secrets-store CSI volume runs. Job and
// CronJob templates therefore mount the secrets-store volume whenever any secrets
// exist so the synced K8s Secret is available before env vars resolve.
resource "kubernetes_manifest" "secret_provider_class" {
  count = length(local.all_secret_keys) > 0 ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.app_name
      namespace = local.app_namespace
      labels    = local.component_labels
    }

    spec = {
      provider = "aws"

      parameters = {
        usePodIdentity = true
        // Each secret gets its own Secrets Manager secret; objectAlias becomes
        // the filename under the mount path and the key in the synced K8s Secret.
        objects = yamlencode([
          for key, arn in nonsensitive(local.all_secrets) : {
            objectName  = arn
            objectType  = "secretsmanager"
            objectAlias = key
          }
        ])
      }

      secretObjects = [
        {
          secretName = local.app_secret_store_name
          type       = "Opaque"
          data = [
            for key in tolist(local.all_secret_keys) : {
              objectName = key // matches objectAlias above
              key        = key
            }
          ]
        }
      ]
    }
  }
}
