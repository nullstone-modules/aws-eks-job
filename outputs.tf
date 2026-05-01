output "region" {
  value       = local.region
  description = "string ||| The region where the job runs."
}

output "service_name" {
  value       = "" // Always blank because we don't create a Kubernetes Service for jobs
  description = "string ||| The name of the kubernetes deployment for the app."
}

output "service_namespace" {
  value       = local.app_namespace
  description = "string ||| The kubernetes namespace where the app resides."
}

output "log_provider" {
  value       = "eks"
  description = "string ||| 'eks'"
}

output "log_reader" {
  value       = module.scaffold.log_reader
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to view logs."
}

output "image_repo_url" {
  value       = module.scaffold.repository_url
  description = "string ||| Job container image url."
}

output "image_pusher" {
  value       = module.scaffold.image_pusher
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to push images."
}

output "deployer" {
  value       = module.scaffold.deployer
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to deploy."
}

output "main_container_name" {
  value       = local.main_container_name
  description = "string ||| The name of the container definition for the primary container"
}

output "job_definition_name" {
  value       = local.job_definition_name
  description = "string ||| The name of the Kubernetes ConfigMap containing the Job template"
}

output "app_security_group_id" {
  value       = aws_security_group.this.id
  description = "string ||| The ID of the security group attached to the job pod."
}

output "private_urls" {
  value       = local.private_urls
  description = "list(string) ||| A list of URLs only accessible inside the network"
}

output "public_urls" {
  value       = local.public_urls
  description = "list(string) ||| A list of URLs accessible to the public"
}

output "private_hosts" {
  value       = local.private_hosts
  description = "list(string) ||| A list of Hostnames only accessible inside the network"
}

output "public_hosts" {
  value       = local.public_hosts
  description = "list(string) ||| A list of Hostnames accessible to the public"
}
