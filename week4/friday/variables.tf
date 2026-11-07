variable "environment" {
    description = "Deployment environment"
    type = string
    default = "staging"
}

variable "ssh_key_name" {
    description = "Name of the existing EC2 key pair"
    type = string
}

variable "vpc_id" {
    description = "ID of the VPC"
    type = string
}

variable "subnet_id" {
    description = "ID of the subnet"
    type = string
}

variable "my_ip" {
    description = "Your local public IP address for SSH access"
    type = string
}