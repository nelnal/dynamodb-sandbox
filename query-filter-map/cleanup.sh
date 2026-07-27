#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh

aws_local dynamodb delete-table --table-name "$TABLE"
echo "Cleanup complete: $TABLE"
