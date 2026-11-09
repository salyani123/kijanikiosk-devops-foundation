terraform {
  required_providers {
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kube_config_path
  config_context = "minikube"
}

resource "kubernetes_namespace" "kijani_staging" {
  metadata {
    name = var.namespace_name
    labels = {
        environment = "staging"
        managed_by = "terraform"
    }
  }
}