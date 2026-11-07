# IAM Least Privilege Design

**Application Task** -> The `kk-payments` backend service needs to securely store daily transaction receipt logs in an AWS S3 storage bucket (`kijanikiosk-payment-receipts`).

## Least Privilege Policy
To adhere to the principle of least privilege, the IAM policy below only grants the `kk-payments` EC2 instance the exact permission it needs (`s3:PutObject`). It restricts that action to a single, specific resource. It inherently denies the ability to read, delete, or list other buckets.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPaymentReceiptWrites",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::kijanikiosk-payment-receipts/*"
    }
  ]
}
```

## Security Reasoning
**Specific Actions** -> By only allowing s3:PutObject, even if the payments server is compromised, an attacker cannot delete existing financial receipts or read sensitive data from other parts of the cloud environment.

**Resource Isolation** -> The Resource ARN restricts access exclusively to the kijanikiosk-payment-receipts bucket. The service has absolutely no access to any other cloud resources.