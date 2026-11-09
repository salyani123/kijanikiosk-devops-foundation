# Capstone Scope Doument

## Problem Statement
The `kk-payments` microservice currently deploys to a single default namespace on a local minikube cluster. There is not isolated staging environment, meaning that code changes cannot be safely validated against production-like environment before release. When a bad image tag is pushed, it deploys directly to the primary environment, and rollback requires manual intervention.

## Track
Track A (Infrastructure first)

## What I will build
- Terraform configuration to provision an isolated `kijani-staging` kubernetes namespace.
- Ansible playbook to configure environment specific ConfigMaps (`like DB_Host`)to separate code and configuration.
- Jenkins CI/CD pipeline to automate a staging deployment on a merge to `main`, run a smoke test against the health endpoint, and pause at a production approval gate.
- Prometheus alert rule configured to fire when the `kk-payments` error rate exceeds 5% for 2 minutes.
- Integration connecting the `kk-payments` staging deployment to the `kk-payments-receipts-staging` S3 bucket to trigger the serverless receipt chain.

## What Is Out Of Scope
- Multi cluster kubernetes architecture (excluded because both staging and production will run on the same local minikube cluster to conserve system resources).
- Application code feature development (excluded because the focus is strictly on extending the infrastructure delivery pipeline).

## Success Criteria
1. A push to main triggers staging deployment automatically.
2. The production gate requires explicit approval and shows the staging health check result.
3. A deliberately introduced bad image triggers an automated rollback in staging before reaching prodcution.

## Architecture Diagram
![Architecture Diagram](architecture.png)
