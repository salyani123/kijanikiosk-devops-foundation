# Peer Feeback Review
### Reviewer: @Anm-hub (Github)

## Issue #1 — Root README does not direct reviewers to the capstone

- **Issue:** The root [README.md](../../README.md) showed only the Week 2 baseline and did not link reviewers to the capstone submission.
- **Severity:** Minor improvement (documentation).
- **Resolution:** Added a prominent “Capstone submission” section at the top of the root README with a direct link to the capstone README and a brief guide to setup and verification.
- **Evidence:** Commit c246600

## Issue #2 — Test plan omits staging environment setup commands

- **Issue:** The test plan required an existing staging namespace/configuration and hostname mapping but did not explain how a fresh reviewer could create them.
- **Severity:** Minor improvement (documentation).
- **Resolution:** Added ordered Terraform init/apply and Ansible staging configuration commands, plus the `/etc/hosts` command mapping `staging.kijani.local` to the Minikube IP.
- **Evidence:** Commit c246600

## Issue #3 — Test plan lacks a local S3 object verification command

- **Issue:** The Serverless receipt test expected test objects to be written to the local S3 simulator but did not show how to inspect the bucket.
- **Severity:** Minor improvement (documentation).
- **Resolution:** Added an AWS CLI `s3 ls` command using the simulator endpoint and staging receipts bucket, and clarified the expected listing result.
- **Evidence:** Commit c246600
