terraform {
    backend "s3" {
        bucket = "kijanikiosk-tfstate-yusuf"
        key = "staging/terraform.tfstate"
        region = "eu-west-1"
        use_lockfile = true
        encrypt = true
    }
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

provider "aws" {
    region = "eu-west-1"
}

data "aws_ami" "ubuntu_22_04" {
    most_recent = true
    owners      = ["099720109477"] # Canonical
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}

resource "aws_security_group" "app" {
    name = "kijanikiosk-sg"
    description = "Allow SSH and HTTP access"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

locals {
    servers = {
        api = { instance_type = "t3.micro" }
        payments = { instance_type = "t3.micro" }
        logs = { instance_type = "t3.micro" }
    }
}

module "app_servers" {
    source = "./modules/app_server"
    for_each = local.servers
    
    name = each.key
    environment = var.environment
    instance_type = each.value.instance_type
    ami_id = data.aws_ami.ubuntu_22_04.id
    key_name = var.ssh_key_name
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.app.id]
}