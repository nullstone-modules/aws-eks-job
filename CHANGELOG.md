# 0.3.0 (Sep 30, 2026)
* Upgraded `nullstone-io/ns` provider to `~> 0.13.0`.
* Replaced `ns_env_variables` and `ns_secret_keys` with the layered `ns_env_layout`, `ns_env_values`, and `ns_env_platform_data` data sources to aggregate environment variables and secrets.
* Emitted the `env` platform data record, including the source of each variable and the Kubernetes secret key of each managed secret.
* Upgraded capability scaffolding to emit `capability` on capability outputs and `cap_prefixes`.

# 0.2.0 (Jul 25, 2026)
* Added support for structured env var references: `{{ k8s.field(...) }}`, `{{ k8s.configMap(...) }}`, `{{ k8s.resourceField(...) }}`, and `{{ k8s.fileKey(...) }}`. Previously these were silently dropped — only plain values and `{{ secret(...) }}` were rendered. They are now emitted in both the job definition template (`nullstone exec`) and cron jobs. `fileKey` requires Kubernetes 1.34+ with the `EnvFiles` feature gate.

# 0.1.1 (Jul 15, 2026)
* Added `image_repo_name` to capability `app_metadata`.

# 0.1.0 (Jun 19, 2026)
* Initial release
