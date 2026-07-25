# 0.2.0 (Jul 25, 2026)
* Added support for structured env var references: `{{ k8s.field(...) }}`, `{{ k8s.configMap(...) }}`, `{{ k8s.resourceField(...) }}`, and `{{ k8s.fileKey(...) }}`. Previously these were silently dropped — only plain values and `{{ secret(...) }}` were rendered. They are now emitted in both the job definition template (`nullstone exec`) and cron jobs. `fileKey` requires Kubernetes 1.34+ with the `EnvFiles` feature gate.

# 0.1.1 (Jul 15, 2026)
* Added `image_repo_name` to capability `app_metadata`.

# 0.1.0 (Jun 19, 2026)
* Initial release
