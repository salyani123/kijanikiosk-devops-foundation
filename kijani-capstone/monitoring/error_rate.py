#!/usr/bin/env python3
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


here = Path(__file__).resolve().parent
logs = subprocess.run(
    [
        "kubectl", "logs", "-n", "kijani-staging",
        "-l", "app=kk-payments", "--all-containers=true",
        "--prefix=true", "--since=2m",
    ],
    check=True,
    capture_output=True,
    text=True,
).stdout.splitlines()

receipt_requests = []
for line in logs:
    try:
        event = json.loads(line[line.index("{"):])
        if (
            event.get("event") == "http_request"
            and event.get("path") in {"/receipts", "/payments/receipts"}
            and not event.get("synthetic")
        ):
            receipt_requests.append(int(event["statusCode"]))
    except (ValueError, KeyError, json.JSONDecodeError):
        continue

receipt_errors = sum(status >= 500 for status in receipt_requests)
receipt_rate = receipt_errors / len(receipt_requests) if receipt_requests else 0
result = "NO DATA" if not receipt_requests else "ABOVE TARGET" if receipt_rate > 0.001 else "WITHIN TARGET"

summary = (
    "kk-payments staging receipt error-rate summary\n"
    f"Time: {datetime.now(timezone.utc).isoformat()}\n"
    f"Window: last 2 minutes\n"
    f"Receipt HTTP 5xx errors: {receipt_errors}/{len(receipt_requests)} ({receipt_rate:.2%})\n"
    f"Target: fewer than 0.1% HTTP 5xx errors\n"
    f"Result: {result}\n"
)

report = here / "error-rate-summary.txt"
report.write_text(summary, encoding="utf-8")
print(summary, end="")
print(f"Saved to {report}")
