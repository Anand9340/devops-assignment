#!/usr/bin/env bash

set -euo pipefail

BASE="${1:?usage: smoke_test.sh <base-url>}"

echo "Checking health..."

curl -fsS "$BASE/health"

echo

echo "Sending notification..."

TID=$(curl -fsS -X POST \
  "$BASE/notify/?email=smoke@example.com" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["task_id"])')

echo "Task ID: $TID"

for i in $(seq 1 40); do

  STATUS=$(curl -fsS \
    "$BASE/task_status/$TID" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["status"])')

  echo "Attempt $i: $STATUS"

  if [ "$STATUS" = "completed" ]; then
    echo "Smoke test successful"
    exit 0
  fi

  if [ "$STATUS" = "failed" ]; then
    echo "Task failed"
    exit 1
  fi

  sleep 2

done

echo "Smoke test timed out"
exit 1
