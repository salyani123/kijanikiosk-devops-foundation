# Reflection

## 1. Where were you tempted to take shortcuts?
I was most tempted to take shortcuts with the IAM policy design. Writing a strict least-privilege JSON policy for a single S3 bucket requires careful syntax and precise resource ARNs. It would have been much faster to assign a generic `AmazonS3FullAccess` managed role to the EC2 instances, even though it heavily violates security best practices. I was also tempted to place all resources in a single public subnet to avoid the complexity of route tables and private routing logic.

## 2. Which architectural decision required the most reasoning?
The network segmentation and routing logic required the most careful reasoning. Deciding exactly which components (like the Load Balancer) belonged in the public subnet connected to the Internet Gateway, versus placing the core API, payments service, and databases in the completely isolated private subnet, required balancing system accessibility with strict security constraints. 

## 3. If the KijaniKiosk platform grows significantly, what would you improve first?
I would immediately improve how this infrastructure is deployed. While manually designing the network architecture and IAM policies in documentation is critical for establishing the foundational blueprint, scaling up across multiple availability zones requires automation. I would migrate these architectural concepts into a formal Infrastructure as Code (IaC) tool like Terraform to ensure the environment is provisioned exactly as documented without human error.