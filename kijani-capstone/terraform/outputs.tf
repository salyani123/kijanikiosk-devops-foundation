output "staging_namespace" {
    description = "The provisioned staging namespace"
    value = kubernetes_namespace.kijani_staging.metadata[0].name
}