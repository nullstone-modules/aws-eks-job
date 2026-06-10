// Cron jobs are pulled from capability outputs
// This ensures that this module controls the definition of the spec
// Otherwise, the cron capability would have tons of code to maintain for controlling the spec (this would be brittle to changes)

locals {
  cron_jobs = {
    for cj in local.capabilities.cron_jobs : "${cj.cap_tf_id}-${cj.name}" => {
      name                          = cj.name
      labels                        = lookup(cj, "labels", {})
      schedule                      = cj.schedule
      concurrency_policy            = lookup(cj, "concurrency_policy", null)
      suspend                       = lookup(cj, "suspend", false)
      failed_jobs_history_limit     = lookup(cj, "failed_jobs_history_limit", null)
      successful_jobs_history_limit = lookup(cj, "successful_jobs_history_limit", null)
      timezone                      = lookup(cj, "timezone", null)
      starting_deadline_seconds     = lookup(cj, "starting_deadline_seconds", null)
      ttl_seconds_after_finished    = lookup(cj, "ttl_seconds_after_finished", null)
      env                           = lookup(cj, "env", {})
    }
  }
}

resource "kubernetes_cron_job_v1" "this" {
  for_each = local.cron_jobs

  metadata {
    namespace = local.app_namespace
    name      = each.key
    labels    = each.value.labels
  }

  spec {
    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#schedule-syntax
    schedule = each.value.schedule

    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy
    // Allow|Forbid|Replace
    concurrency_policy = each.value.concurrency_policy

    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#schedule-suspension
    // This provides a way to disable the cron
    suspend = each.value.suspend

    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits
    failed_jobs_history_limit     = each.value.failed_jobs_history_limit
    successful_jobs_history_limit = each.value.successful_jobs_history_limit

    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones
    timezone = each.value.timezone

    // https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#job-creation
    starting_deadline_seconds = each.value.starting_deadline_seconds

    job_template {
      metadata {
        namespace = local.kubernetes_namespace
        labels    = local.app_labels
      }
      spec {
        completions                = 1                                     // we only want to run 1 job
        backoff_limit              = 0                                     // do not retry jobs
        ttl_seconds_after_finished = each.value.ttl_seconds_after_finished // retain completed jobs

        template {
          metadata {
            labels = local.app_labels
          }
          spec {
            restart_policy       = "Never"
            service_account_name = kubernetes_service_account_v1.app.metadata[0].name

            container {
              name  = local.main_container_name
              image = local.effective_image_url
              args  = local.command

              resources {
                requests = {
                  cpu    = var.cpu
                  memory = var.memory
                }

                limits = merge(
                  var.max_cpu != "" ? { cpu = var.max_cpu } : {},
                  var.max_memory != "" ? { memory = var.max_memory } : {},
                )
              }

              dynamic "env" {
                for_each = local.env_vars_plain

                content {
                  name  = env.key
                  value = env.value
                }
              }

              // Per-cron env injected by the cron-trigger capability (e.g. NULLSTONE_TRIGGER)
              dynamic "env" {
                for_each = each.value.env

                content {
                  name  = env.key
                  value = env.value
                }
              }

              dynamic "env" {
                for_each = toset(local.all_secret_keys)

                content {
                  name = env.value
                  value_from {
                    secret_key_ref {
                      name = local.app_secret_store_name
                      key  = env.value
                    }
                  }
                }
              }

              dynamic "volume_mount" {
                for_each = local.volume_mounts

                content {
                  name              = volume_mount.key
                  mount_path        = volume_mount.value.mount_path
                  sub_path          = volume_mount.value.sub_path
                  mount_propagation = volume_mount.value.mount_propagation
                  read_only         = volume_mount.value.read_only
                  sub_path_expr     = volume_mount.value.sub_path_expr
                }
              }

              // Mount secrets-store CSI volume so the SecretProviderClass syncs
              // its K8s Secret before secretKeyRef env vars resolve.
              dynamic "volume_mount" {
                for_each = local.has_secrets ? [1] : []

                content {
                  name       = "secrets-store"
                  mount_path = "/mnt/secrets-store"
                  read_only  = true
                }
              }
            }

            dynamic "volume" {
              for_each = local.volumes

              content {
                name = volume.value.name

                dynamic "empty_dir" {
                  for_each = volume.value.empty_dir == null ? [] : [1]
                  content {}
                }

                dynamic "persistent_volume_claim" {
                  for_each = volume.value.persistent_volume_claim == null ? [] : [volume.value.persistent_volume_claim]
                  iterator = pvc

                  content {
                    claim_name = pvc.value.claim_name
                    read_only  = lookup(pvc.value, "read_only", null)
                  }
                }

                dynamic "host_path" {
                  for_each = volume.value.host_path == null ? [] : [volume.value.host_path]
                  iterator = hp

                  content {
                    type = hp.value.type
                    path = hp.value.path
                  }
                }
              }
            }

            dynamic "volume" {
              for_each = local.has_secrets ? [1] : []

              content {
                name = "secrets-store"

                csi {
                  driver    = "secrets-store.csi.k8s.io"
                  read_only = true

                  volume_attributes = {
                    secretProviderClass = local.spc_name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
