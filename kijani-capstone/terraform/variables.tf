variable "namespace_name" {
  description = "Name of the staging namespace"
  type = string
  default = "kijani-staging"
}

variable "kube_config_path" {
    description = "Path to the kube config file"
    type = string
    default = "~/.kube/config"
}

variable "environemt_label" {
    description = "Environment label for resources"
    type = string
    default = "staging"
}