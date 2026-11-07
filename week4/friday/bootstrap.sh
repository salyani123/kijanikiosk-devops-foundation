#!/bin/bash
set -e

echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket kijanikiosk-tfstate-yusuf \
    --region eu-west-1 \
    --create-bucket-configuration LocationConstraint=eu-west-1

echo "Bootstrap complete."