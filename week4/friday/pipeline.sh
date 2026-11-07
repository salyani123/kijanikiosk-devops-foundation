#!/bin/bash
set -e

echo "Deploying infrastructure with Terraform..."
terraform apply -auto-approve

echo "Extracting public IPs..."
API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

echo "Generating Ansible inventory..."
cat <<EOF > inventory.ini
[kijanikiosk_api]
api-staging ansible_host=$API_IP

[kijanikiosk_payments]
payments-staging ansible_host=$PAYMENTS_IP

[kijanikiosk_logs]
logs-staging ansible_host=$LOGS_IP

[kijanikiosk:children]
kijanikiosk_api
kijanikiosk_payments
kijanikiosk_logs
EOF

echo "Inventory generated successfully."
sleep 30

echo "Configuring Servers with Ansible..."
ansible-playbook -i inventory.ini kijanikiosk.yml