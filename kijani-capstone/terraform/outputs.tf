output "staging_namespace" {
    description = "The provisioned staging namespace"
    value = kubernetes_namespace.staging_namespace.metadata[0].name
}