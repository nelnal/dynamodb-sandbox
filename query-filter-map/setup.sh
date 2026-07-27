#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh

aws_local dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions \
      AttributeName=pk,AttributeType=S \
      AttributeName=sk,AttributeType=S \
      AttributeName=area,AttributeType=S \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --global-secondary-indexes \
      "IndexName=$GSI,KeySchema=[{AttributeName=area,KeyType=HASH},{AttributeName=pk,KeyType=RANGE}],Projection={ProjectionType=ALL}" \
  --billing-mode PAY_PER_REQUEST

aws_local dynamodb wait table-exists --table-name "$TABLE"

jq -c '.[]' ./data.json | while read -r item; do
  aws_local dynamodb put-item --table-name "$TABLE" --item "$item"
done

echo "Setup complete: $TABLE"
