#!/usr/bin/env bash
# Builds the Dart server for Lambda and deploys the Donut party backend.
# Needs the guardrails stack deployed first. Usage: ./deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

REGION=${AWS_REGION:-us-east-2}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET=guardrails-$ACCOUNT-$REGION
TOPIC=arn:aws:sns:$REGION:$ACCOUNT:guardrails-game-shutoff

# A native Linux binary named bootstrap is the whole function
mkdir -p lambda
(cd ../../packages/donut_server && dart pub get >/dev/null &&
  dart compile exe bin/bootstrap.dart --target-os=linux --target-arch=arm64 -o build/bootstrap >/dev/null)
cp ../../packages/donut_server/build/bootstrap lambda/bootstrap

aws cloudformation package --region "$REGION" --template-file template.yaml \
  --s3-bucket "$BUCKET" --s3-prefix game-code --output-template-file packaged.yaml >/dev/null
aws cloudformation deploy --region "$REGION" --stack-name donut-game \
  --template-file packaged.yaml --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides GameShutoffTopicArn="$TOPIC" \
  --tags app=donut
rm -f packaged.yaml

URL=$(aws cloudformation describe-stacks --region "$REGION" --stack-name donut-game \
  --query "Stacks[0].Outputs[?OutputKey=='WebSocketUrl'].OutputValue" --output text)
echo "Deployed. The app connects to: $URL"
