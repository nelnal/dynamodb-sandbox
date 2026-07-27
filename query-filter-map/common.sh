ENDPOINT="http://127.0.0.1:8000"
REGION="us-west-2"
TABLE="QueryFilterMapTest"
GSI="AreaIndex"

# dynamodb-local ignores credentials but the AWS CLI still requires some to be set
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-dummy}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-dummy}"

# stdout がターミナルだと aws cli が出力を less に渡してしまうため無効化する
export AWS_PAGER=""

aws_local() {
  aws --endpoint-url "$ENDPOINT" --region "$REGION" "$@"
}
