#!/usr/bin/env bash
# Opens the Donut admin dashboard: downloads the party server's daily
# counts from S3 and builds a page on this Mac. Nothing is served online.
# Usage: ./dashboard.sh
set -euo pipefail
cd "$(dirname "$0")"

REGION=${AWS_REGION:-us-east-2}
BUCKET=$(aws cloudformation describe-stack-resource --region "$REGION" --stack-name donut-game \
  --logical-resource-id TablesBucket --query StackResourceDetail.PhysicalResourceId --output text)
OUT=${TMPDIR:-/tmp}/donut-dashboard
mkdir -p "$OUT"
aws s3 sync --region "$REGION" --quiet --delete "s3://$BUCKET/stats/days" "$OUT/days"
aws s3 sync --region "$REGION" --quiet --delete "s3://$BUCKET/stats/uniques" "$OUT/uniques"
# Live right now: tables touched in the last 15 minutes
LIVE=$(aws s3api list-objects-v2 --region "$REGION" --bucket "$BUCKET" --prefix tables/ \
  --query "length(Contents[?ends_with(Key, 'state.json') && LastModified>='$(date -u -v-15M +%Y-%m-%dT%H:%M:%S)'])" \
  --output text 2>/dev/null || echo 0)
python3 -I dashboard.py "$OUT" "${LIVE/None/0}" > "$OUT/index.html"
echo "Dashboard: $OUT/index.html"
open "$OUT/index.html" 2>/dev/null || true
