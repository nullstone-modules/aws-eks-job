terraform {
  required_providers {
    ns = {
      source  = "registry.terraform.io/nullstone-io/ns"
      version = "~> 0.10.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
