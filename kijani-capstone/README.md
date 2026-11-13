# KijaniKiosk DevOps Capstone

## What is this?

This project deploys the `kk-payments` receipt API to staging and production
namespaces on a local Minikube cluster, using Jenkins for delivery, Terraform
and Ansible for environment setup, and a local Serverless/S3 simulator for
receipt processing; it demonstrates how to validate a change in staging before
an operator approves production deployment.

## Architecture

![Architecture diagram](docs/architecture.png)

- **Jenkins:** A single Pipeline job checks out its configured source, reads
  `kijani-capstone/Jenkinsfile`, deploys staging, runs a health check, and
  pauses for approval before production.
- **Terraform and Ansible:** Terraform provisions the staging namespace, and
  Ansible configures per-environment application ConfigMaps and Secrets.
- **Kubernetes and Ingress:** Two `kk-payments` replicas run in staging; the
  production deployment uses the `default` namespace on the same Minikube
  cluster, with NGINX Ingress routing each hostname to its service.
- **Receipt service:** `kk-payments` forwards receipt requests to the local
  Serverless HTTP API, whose handlers write to simulated S3 buckets and
  process object-created events.
- **Log monitoring:** The app writes structured request logs; a Python script
  summarizes recent staging receipt 5xx responses, and a staging-only route
  generates synthetic successes and failures for testing.

## Prerequisites

Install these before setup:

- Linux host with `sudo`, Git, Bash, `curl`, and a text editor such as `nano`.
- Docker Engine and Docker Compose v2.
- Minikube and `kubectl` compatible with its Kubernetes version.
- Node.js 20.x and npm (for the local Serverless simulator).
- Python 3 (for the log report).
- Internet access to pull the public application image and Jenkins plugins.

Jenkins runs in the provided Docker image. That image installs Terraform
1.5.7, Ansible, Python, `kubectl`, and Java 17. Manual infrastructure setup
outside Jenkins also requires Terraform and Ansible with the
`kubernetes.core` collection.

## Setup

Run these steps in order from a terminal on the Minikube host.

1. Clone the repository:

   ```bash
   git clone https://github.com/salyani123/kijanikiosk-devops-foundation.git
   cd kijanikiosk-devops-foundation
   ```

2. Start Minikube and enable NGINX Ingress:

   ```bash
   minikube start --driver=docker
   minikube addons enable ingress
   ```

3. Map the application hostnames to the Minikube IP:

   ```bash
   printf '%s staging.kijani.local kijani.local\n' "$(minikube ip)" \
     | sudo tee -a /etc/hosts
   ```

4. Configure Jenkins. Copy the example environment file, edit the values, and
   start Jenkins:

   ```bash
   cd kijani-capstone/jenkins-docker
   cp .env.example .env
   nano .env
   ```

   In `.env`, set `HOST_HOME` to the absolute path of your home directory, and
   replace the example Jenkins admin ID and password with your own values. Do
   not commit `.env`. Then run:

   ```bash
   docker compose up -d --build
   ```

   Jenkins is available at `http://localhost:8080`. Its Compose setup expects
   Minikube's Docker network to be named `minikube` and mounts the host
   kubeconfig and Minikube files into the container.

5. Open a second terminal at the cloned repository root and start the staging
   Serverless simulator:

   ```bash
   cd kijani-capstone/kijani-serverless
   npm install
   npx serverless offline start --stage staging
   ```

   Leave this process running when exercising receipt requests. Staging is
   configured to use the local HTTP API on port `3000` and S3 simulator on
   port `4569`.

The application image is pulled from the public image repository using the tag
in `kijani-capstone/k8s/kk-payments-deployment.yaml`; this setup does not build
an image.

## How to run the pipeline

Start the pipeline manually from Jenkins:

1. Open `http://localhost:8080` and sign in with the admin credentials from
   `.env`.
2. Open `kijani-capstone-main` and select **Build Now**.
3. Watch the stages:
   - **Verify IaC:** runs Terraform validation and Ansible syntax checks.
   - **Provision Infrastructure (Staging):** imports or creates the staging
     namespace through Terraform.
   - **Configure Environment (Staging):** creates the staging ConfigMap and
     Secret with Ansible.
   - **Deploy to Staging:** applies the Deployment, Service, and staging
     Ingress, then waits for rollout.
   - **Smoke Test:** calls `/health` from a temporary pod.
   - **Approval Gate:** pauses for an administrator's approval.
   - **Production stages:** after approval, configures and deploys to the
     `default` namespace.

The pipeline has a 15-minute overall timeout, so the approval pause is not
indefinite.

## How to verify it works

### Staging deployment and health

After the Jenkins staging stages finish, check the rollout and health endpoint:

```bash
kubectl rollout status deployment/kk-payments -n kijani-staging
kubectl run health-check --rm -i --restart=Never -n kijani-staging \
  --image=curlimages/curl -- \
  curl -sSf http://kk-payments-service:3001/health
```

Expected: rollout succeeds and `/health` returns a healthy response. The
pipeline should then pause at the production approval gate.

### Receipt processing

With the local Serverless simulator running, submit a unique test receipt:

```bash
curl -i -X POST http://staging.kijani.local/payments/receipts \
  -H 'Content-Type: application/json' \
  -d '{"orderId":"TEST-RECEIPT-001","amount":100,"currency":"KES"}'
```

Expected: the request succeeds and the Serverless terminal shows receipt
generation, processing, and notification events. Test requests may write
objects to the staging local S3 simulator.

### Synthetic error-rate test

From `kijani-capstone/`, run:

```bash
./monitoring/trigger-incident.sh
```

Expected: 50 requests go to `/payments/simulate-traffic`; the helper reports
the number of HTTP 200 and 500 responses. This route is intended for staging
only, and its synthetic requests are excluded from the receipt report.

### Receipt error-rate report

Send a batch of uniquely identified test receipts as above, then from
`kijani-capstone/` run:

```bash
python3 monitoring/error_rate.py
```

Expected: the report counts non-synthetic `/receipts` HTTP 5xx responses in
staging pod logs from the last two minutes, compares the result with the Week 7
target of fewer than 0.1%, and writes
`monitoring/error-rate-summary.txt`. It reports `NO DATA` if there were no
receipt requests in the time window.

### Scope success criteria status

1. **Pipeline deployment:** a reviewer can manually start the Jenkins job and
   observe the staging deployment and health check.
2. **Approval is required after staging health check:** implemented by the
   pipeline's approval gate.
3. **Bad image automatically rolls back staging:** the pipeline now attempts
   to restore the previous staging revision after a failed rollout or smoke
   test, when a prior revision exists.

## Known limitations

- The monitoring report is a manual two-minute sample, not a continuous alert
  and not the Week 7 rolling 30-day SLO calculation; logs are not retained for
  that duration.
- Small receipt samples have coarse error-rate resolution: one failure in 20
  requests is 5%, far above a 0.1% target.
- The public application image is referenced by a fixed tag in the manifest;
  Jenkins does not build, publish, or verify that image against the source in
  this repository.
- Staging rollback requires an earlier successful Deployment revision; on the
  first deployment there is no previous version to restore. Production and
  staging share one Minikube cluster, and production currently uses the
  `default` namespace.
- The Serverless/S3 setup is a local simulator, not AWS production
  infrastructure. Values in the Ansible environment files are examples and
  must not be used as real production secrets.
- The `/health` endpoint checks that the app responds; it does not verify the
  receipt service dependency.
- The current implementation does not include production-grade secret
  management, external durable log storage, or alert notification delivery.
