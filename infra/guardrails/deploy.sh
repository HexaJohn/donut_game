#!/usr/bin/env bash
# Deploys the cost guardrails. Usage: ./deploy.sh you@example.com
set -euo pipefail
cd "$(dirname "$0")"

EMAIL=${1:?usage: deploy.sh alert-email}
REGION=${AWS_REGION:-us-east-2}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET=guardrails-$ACCOUNT-$REGION

# A private bucket for the switch's code and its record of what it switched off
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
  aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging 'TagSet=[{Key=app,Value=guardrails}]'
fi

aws cloudformation package --region "$REGION" --template-file template.yaml \
  --s3-bucket "$BUCKET" --s3-prefix code --output-template-file packaged.yaml >/dev/null
aws cloudformation deploy --region "$REGION" --stack-name guardrails \
  --template-file packaged.yaml --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides AlertEmail="$EMAIL" StateBucket="$BUCKET"
rm -f packaged.yaml
echo "Deployed. Confirm the three subscription emails AWS sent to $EMAIL."
