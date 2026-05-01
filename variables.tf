variable "cpu" {
  type        = string
  default     = "0.5"
  description = <<EOF
The amount of CPU to request for the job (maps to resources.requests.cpu in the k8s pod spec).
The k8s scheduler uses this value to decide which node to place the pod on.
You can specify CPU in cores (e.g. "0.5") or milliCPU (e.g. "500m").
By default, this is set to 0.5 CPU.
EOF
}

variable "max_cpu" {
  type        = string
  default     = ""
  description = <<EOF
The maximum amount of CPU the job can use (maps to resources.limits.cpu in the k8s pod spec).
If the job exceeds this limit, it will be throttled.
You can specify CPU in cores (e.g. "1") or milliCPU (e.g. "1000m").
By default, this is unset which means there is no CPU limit.
EOF
}

variable "memory" {
  type        = string
  default     = "512Mi"
  description = <<EOF
The amount of memory to request for the job (maps to resources.requests.memory in the k8s pod spec).
The k8s scheduler uses this value to decide which node to place the pod on.
Memory is measured in Mi (megabytes) or Gi (gigabytes).
By default, this is set to 512Mi (0.5Gi).
EOF
}

variable "max_memory" {
  type        = string
  default     = ""
  description = <<EOF
The maximum amount of memory the job can use (maps to resources.limits.memory in the k8s pod spec).
If the job exceeds this limit, it will be killed with an OOMKilled status.
Memory is measured in Mi (megabytes) or Gi (gigabytes).
By default, this is unset which means there is no memory limit.
EOF
}

variable "command" {
  type        = list(string)
  default     = []
  description = <<EOF
This overrides the `CMD` specified in the image.
Specify a blank list to use the image's `CMD`.
Each token in the command is an item in the list.
For example, `echo "Hello World"` would be represented as ["echo", "\"Hello World\""].
EOF
}

variable "image_url" {
  type    = string
  default = ""

  description = <<EOF
This allows you to override the image used for the application.
This removes management of build artifacts through Nullstone, but allows you to use pre-built artifacts managed externally.

If blank, Nullstone will create an image repository and provide management of images.

If you configure image_url, you can still use `nullstone deploy --version=<...>` to deploy a specific image tag.
EOF
}

variable "disable_security_group" {
  type        = bool
  default     = false
  description = <<EOF
Set to true to disable the use of security groups for this app's pods.
This will eliminate the need for an ENI (which are limited per node).
EOF
}
