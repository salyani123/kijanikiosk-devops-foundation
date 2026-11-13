# KijaniKiosk Capstone Test Plan

This plan describes checks for the current Minikube, Jenkins, local Serverless,
and log-based monitoring setup. Run destructive or production deployment tests
only when explicitly intended.

## Prerequisites

- Minikube is running with ingress enabled.
- `kubectl` is using the intended Minikube context.
- The `kijani-staging` namespace and staging app configuration exist.
- The staging app is running the updated image with structured request logs
  and the staging-only `/simulate-traffic` route.
- Host DNS maps `staging.kijani.local` to the Minikube IP.

## 1. Staging deployment and health check

**Action**

1. Apply the staging Deployment, Service, and Ingress manifests (or run the
   Jenkins pipeline through its staging deployment stage).
2. Wait for rollout:

   ```bash
   kubectl rollout status deployment/kk-payments \
     -n kijani-staging --timeout=180s
   ```

3. Check the in-cluster health endpoint:

   ```bash
   kubectl run health-check --rm -i --restart=Never \
     -n kijani-staging --image=curlimages/curl -- \
     curl -sSf http://kk-payments-service:3001/health
   ```

**Expected result**

- Deployment rollout completes and the health endpoint returns HTTP 200.
- The Jenkins pipeline pauses for manual approval before its production stage.

**Tester Feedback:** [Pass/Fail - Comments]

## 2. Serverless receipt flow

**Action**

1. Start the local Serverless stack from `kijani-capstone/kijani-serverless`:

   ```bash
   npx serverless offline start --stage staging
   ```

2. Send a uniquely identified receipt through the staging Ingress:

   ```bash
   curl -i -X POST http://staging.kijani.local/payments/receipts \
     -H 'Content-Type: application/json' \
     -d '{"orderId":"TEST-RECEIPT-001","amount":100,"currency":"KES"}'
   ```

**Expected result**

- The app returns a successful response when the local receipt service is
  available.
- The Serverless logs show receipt generation followed by processor and
  notifier activity.
- Test objects are written to the staging local S3 simulator. Use unique
  order IDs when repeating the test.

**Tester Feedback:** [Pass/Fail - Comments]

## 3. Synthetic request logging

**Action**

From `kijani-capstone/`, run:

```bash
./monitoring/trigger-incident.sh
```

**Expected result**

- The helper sends 50 requests to the staging-only `/simulate-traffic` route.
- Each response is HTTP 200 or 500; the helper summarizes the observed counts.
- The route is unavailable outside staging and synthetic requests are excluded
  from the receipt SLO report.

**Tester Feedback:** [Pass/Fail - Comments]

## 4. Receipt error-rate report

**Action**

1. Ensure the updated image and local Serverless stack are running.
2. Send a batch of uniquely identified receipts to
   `http://staging.kijani.local/payments/receipts`.
3. From `kijani-capstone/`, run:

   ```bash
   python3 monitoring/error_rate.py
   ```

**Expected result**

- The report counts non-synthetic `/receipts` HTTP 5xx responses from staging
  pod logs in the last two minutes.
- It compares the observed rate with the Week 7 target of fewer than 0.1%.
- It writes the summary to `monitoring/error-rate-summary.txt`, or reports
  `NO DATA` if there were no receipt requests in the time window.

**Tester Feedback:** [Pass/Fail - Comments]

**Limitations**

- This is a short two-minute sample, not the rolling 30-day SLO
  measurement; the current setup does not retain or aggregate 30 days of logs.
- Small batches have coarse percentage resolution. For example, with 20
  requests, one failure is already a 5% observed error rate.
- This is a log-based report, not a Prometheus alert or continuous notification.

## Test record

| Test | Result | Notes |
|---|---|---|
| Staging deployment and health check | [Pass/Fail] | |
| Serverless receipt flow | [Pass/Fail] | |
| Synthetic request logging | [Pass/Fail] | |
| Receipt error-rate report | [Pass/Fail] | |
