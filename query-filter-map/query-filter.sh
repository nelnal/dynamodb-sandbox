#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh

echo "=== 基本パターン（ExpressionAttributeNames のプレースホルダーなし） ==="

echo "### customer: profile.tier = premium"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "profile.tier = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#customer"}, ":val": {"S": "premium"}}' \
  --query "Items[].{sk: sk.S, tier: profile.M.tier.S, country: profile.M.country.S}" \
  --output table

echo "### order: details.phase = shipped"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "details.phase = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#order"}, ":val": {"S": "shipped"}}' \
  --query "Items[].{sk: sk.S, phase: details.M.phase.S, priority: details.M.priority.S}" \
  --output table

echo "### device: spec.os = ios"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "spec.os = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#device"}, ":val": {"S": "ios"}}' \
  --query "Items[].{sk: sk.S, os: spec.M.os.S, model: spec.M.model.S}" \
  --output table

echo "### account (3-tier): billing.subscription.tier = gold"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "billing.subscription.tier = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#account"}, ":val": {"S": "gold"}}' \
  --query "Items[].{sk: sk.S, tier: billing.M.subscription.M.tier.S, period: billing.M.subscription.M.period.S}" \
  --output table

echo "### shipment (4-tier / String): cargo.box.dimension.measure = cm"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "cargo.box.dimension.measure = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#shipment"}, ":val": {"S": "cm"}}' \
  --query "Items[].{sk: sk.S, measure: cargo.M.box.M.dimension.M.measure.S, amount: cargo.M.box.M.dimension.M.amount.N}" \
  --output table

echo "### shipment (4-tier / Number): cargo.box.dimension.amount = 30"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "cargo.box.dimension.amount = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#shipment"}, ":val": {"N": "30"}}' \
  --query "Items[].{sk: sk.S, measure: cargo.M.box.M.dimension.M.measure.S, amount: cargo.M.box.M.dimension.M.amount.N}" \
  --output table

echo "### shipment (4-tier / Map): cargo.box.dimension.detail = {grade: A, weight: 5}"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "cargo.box.dimension.detail = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#shipment"}, ":val": {"M": {"grade": {"S": "A"}, "weight": {"N": "5"}}}}' \
  --query "Items[].{sk: sk.S, detail: cargo.M.box.M.dimension.M.detail.M}" \
  --output table

echo "### shipment (5-tier / String): cargo.box.dimension.detail.grade = A"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "cargo.box.dimension.detail.grade = :val" \
  --expression-attribute-values '{":pk": {"S": "GROUP#shipment"}, ":val": {"S": "A"}}' \
  --query "Items[].{sk: sk.S, grade: cargo.M.box.M.dimension.M.detail.M.grade.S, weight: cargo.M.box.M.dimension.M.detail.M.weight.N}" \
  --output table

echo "### GSI ($GSI): area = JP, filtered by profile.tier = premium"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --index-name "$GSI" \
  --key-condition-expression "area = :a" \
  --filter-expression "profile.tier = :val" \
  --expression-attribute-values '{":a": {"S": "JP"}, ":val": {"S": "premium"}}' \
  --query "Items[].{pk: pk.S, sk: sk.S, tier: profile.M.tier.S}" \
  --output table

echo
echo "=== 参考パターン（予約語のためプレースホルダーが必要） ==="
echo "### activity: activity.status / activity.region は DynamoDB の予約語のため"
echo "### ExpressionAttributeNames でプレースホルダー（#st, #rg）に置き換えている"

echo "### activity: activity.status = active"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "activity.#st = :val" \
  --expression-attribute-names '{"#st": "status"}' \
  --expression-attribute-values '{":pk": {"S": "GROUP#activity"}, ":val": {"S": "active"}}' \
  --query "Items[].{sk: sk.S, status: activity.M.status.S, region: activity.M.region.S}" \
  --output table

echo "### activity: activity.region = JP"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --key-condition-expression "pk = :pk" \
  --filter-expression "activity.#rg = :val" \
  --expression-attribute-names '{"#rg": "region"}' \
  --expression-attribute-values '{":pk": {"S": "GROUP#activity"}, ":val": {"S": "JP"}}' \
  --query "Items[].{sk: sk.S, status: activity.M.status.S, region: activity.M.region.S}" \
  --output table

echo "### GSI ($GSI): area = JP, filtered by activity.status = active"
aws_local dynamodb query \
  --table-name "$TABLE" \
  --index-name "$GSI" \
  --key-condition-expression "area = :a" \
  --filter-expression "activity.#st = :val" \
  --expression-attribute-names '{"#st": "status"}' \
  --expression-attribute-values '{":a": {"S": "JP"}, ":val": {"S": "active"}}' \
  --query "Items[].{pk: pk.S, sk: sk.S, status: activity.M.status.S}" \
  --output table
