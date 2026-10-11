#!/usr/bin/env bash
# Builds Donut for the web and publishes it at donut.acrovisuals.com.
# Needs the guardrails stack, and an issued certificate (see CERT below).
# Usage: ./deploy.sh            build, deploy the stack, upload
#        ./deploy.sh --upload   skip the stack, just build and upload
set -euo pipefail
cd "$(dirname "$0")"

REGION=us-east-1   # CloudFront's certificates and metrics live here
HOME_REGION=us-east-2
STACK=donut-web
DOMAIN=donut.acrovisuals.com
CERT=arn:aws:acm:us-east-1:165713918534:certificate/ef9bd6ed-eefb-4c69-9967-1fa2e6a5b71f
SWITCH=$(aws lambda get-function --region "$HOME_REGION" --function-name guardrails-switch \
  --query Configuration.FunctionArn --output text)

if [[ "${1:-}" != "--upload" ]]; then
  aws cloudformation deploy --region "$REGION" --stack-name "$STACK" --template-file template.yaml \
    --parameter-overrides DomainName="$DOMAIN" CertificateArn="$CERT" SwitchFunctionArn="$SWITCH" \
    --tags app=donut
  # Let this stack's shutoff topic (us-east-1) call the switch (us-east-2)
  TOPIC=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='ShutoffTopicArn'].OutputValue" --output text)
  aws lambda add-permission --region "$HOME_REGION" --function-name guardrails-switch \
    --statement-id donut-web-shutoff --action lambda:InvokeFunction --principal sns.amazonaws.com \
    --source-arn "$TOPIC" >/dev/null 2>&1 || true
fi

output() {
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}
BUCKET=$(output BucketName)
DISTRIBUTION=$(output DistributionId)

# WebAssembly, with JavaScript for browsers without it. Self-hosted engine
# files: nothing is fetched from Google's CDN
(cd ../.. && flutter build web --release --wasm --no-web-resources-cdn >/dev/null)
WEB=../../build/web

# Sounds, images and the engine change rarely: cache for an hour. The page
# and the game code are checked on every visit, so updates show at once.
ENTRY=(index.html flutter_bootstrap.js flutter.js main.dart.js main.dart.mjs main.dart.wasm flutter_service_worker.js
  version.json manifest.json)
EXCLUDES=()
for file in "${ENTRY[@]}"; do EXCLUDES+=(--exclude "$file"); done
aws s3 sync "$WEB" "s3://$BUCKET" --delete --only-show-errors "${EXCLUDES[@]}" \
  --exclude '*.wasm' --exclude '*.mjs' --cache-control 'public, max-age=3600'
aws s3 sync "$WEB" "s3://$BUCKET" --only-show-errors --exclude '*' --include '*.wasm' \
  --content-type application/wasm --cache-control 'public, max-age=3600'
aws s3 sync "$WEB" "s3://$BUCKET" --only-show-errors --exclude '*' --include '*.mjs' \
  --content-type text/javascript --cache-control 'public, max-age=3600'
for file in "${ENTRY[@]}"; do
  [[ -f "$WEB/$file" ]] || continue
  case "$file" in
    *.wasm) type=application/wasm ;;
    *.mjs | *.js) type=text/javascript ;;
    *.json) type=application/json ;;
    *) type=text/html ;;
  esac
  aws s3 cp "$WEB/$file" "s3://$BUCKET/$file" --only-show-errors --cache-control 'no-cache' --content-type "$type"
done
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION" --paths '/*' >/dev/null

echo "Published. https://$DOMAIN (CloudFront: $(output DistributionDomain))"
