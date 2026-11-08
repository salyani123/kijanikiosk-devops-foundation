# AI Governance Log

## Entry 1: Infrastructure Provisioning
1. **Date:** 2026-11-08
2. **Tool used:** Gemini
3. **Task description:** Generate Terraform configuration to provision the `kijani-staging` namespace on the local Minikube cluster.
4. **What was provided to the AI:** Prompted to write Terraform code using the Kubernetes provider to create the staging namespace.
5. **What the AI produced:** A `main.tf` file containing the provider block and `kubernetes_namespace` resource, and a `variables.tf` file.
6. **What it got right:** Correctly configured the `kubernetes_namespace` resource block and included standard metadata labels (`environment = "staging"`).
7. **What it got wrong:** The AI hardcoded the `config_path = "~/.kube/config"` directly inside the provider block in `main.tf`, which violates configuration portability best practices.
8. **What I changed before applying:** I removed the hardcoded string, created a `kube_config_path` variable in `variables.tf`, and referenced `var.kube_config_path` in `main.tf` to ensure the configuration remains dynamic.