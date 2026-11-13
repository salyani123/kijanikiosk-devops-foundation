#!/bin/bash
set -euo pipefail

url="${STAGING_ERROR_URL:-http://staging.kijani.local/payments/simulate-traffic}"
requests="${ERROR_TEST_REQUESTS:-50}"
successes=0
errors=0

if [[ ! "$requests" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR_TEST_REQUESTS must be a positive integer." >&2
  exit 1
fi

echo "Sending $requests synthetic requests to staging at $url (about 20% are expected to fail)"
for ((i = 1; i <= requests; i++)); do
  status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --max-time 10 "$url" --request POST)"
  case "$status" in
    200) ((successes += 1)) ;;
    500) ((errors += 1)) ;;
    *)
      echo "Expected HTTP 200 or 500 but received $status on request $i." >&2
      exit 1
      ;;
  esac
done

echo "Synthetic results: $successes succeeded, $errors failed."
echo "Calculating the recent staging error rate..."
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
python3 "$script_dir/error_rate.py"