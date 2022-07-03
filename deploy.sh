#/bin/bash

# References
# - https://qiita.com/tcsh/items/e0d592a2b35fea32e9c5#52-integration%E3%81%AE%E4%BD%9C%E6%88%90

# Caution!
# エラー処理はほとんどしていない

set -e

workdir=/path/to/work/directory   # absolute path
package_dir=${workdir}/package
function_path=functions/main/lambda_function.py
package_archive_name=package.zip
model_dir=${workdir}/model
model_name=model.pkl

aws_lambda_func_name=collocation_word_api
aws_s3_bucket=your-bucket-name  # replace your bucket
aws_s3_key=$package_archive_name  # Zipped code name
aws_lambda_role=iam_role_${aws_lambda_func_name}
aws_iam_role_policy_name=policy_${aws_lambda_func_name}
aws_apigateway_name=rest_api_${aws_lambda_func_name}
aws_region=region-name
aws_id=your-account-id

export AWS_REGION=${aws_region}

# Upload code and model to S3
aws s3 cp ${workdir}/${package_archive_name} s3://${aws_s3_bucket}/${aws_s3_key}
aws s3 cp ${model_dir}/${model_name} s3://${aws_s3_bucket}/${model_name}

# Create IAM role
## まずポリシーが設定されていないロールを作成する。
## assume-role-policyでは信頼ポリシーを指定する。
assume_policy=`cat config/assume_role_policy.json | jq -c | sed 's/"//g'`
aws iam create-role --role-name ${aws_lambda_role} --assume-role-policy-document ${assume_policy} > /dev/null
aws_iam_role_arn=`aws iam get-role --role-name ${aws_lambda_role} | jq .Role.Arn | sed 's/"//g'`

## リソースポリシー/ユーザポリシーをさっき作ったロールに付与する。
aws iam put-role-policy \
    --role-name ${aws_lambda_role} \
    --policy-name ${aws_iam_role_policy_name} \
    --policy-document `cat config/role_policy.json | jq -c`

# Create Lambda Function
aws lambda create-function \
    --function-name ${aws_lambda_func_name} \
    --runtime python3.9 \
    --role ${aws_iam_role_arn} \
    --handler lambda_function.lambda_handler \
    --code S3Bucket=${aws_s3_bucket},S3Key=${aws_s3_key} \
    --description  "Search collocation words"\
    --timeout 180 \
    --memory-size 3000 \
    --publish \
    --package-type Zip \
    --environment "Variables={MODEL_BUCKET=${aws_s3_bucket},MODEL_KEY=${aws_s3_key}}" \
    > /dev/null
func_arn=`aws lambda get-function --function-name ${aws_lambda_func_name} | jq .Configuration.FunctionArn | sed 's/"//g'`

# Create API Gateway and Configure API Gateway
## c.f. https://dev.classmethod.jp/articles/getting-started-with-api-gateway-lambda-integration/
api_id=`aws apigateway create-rest-api --name ${aws_apigateway_name} | jq .id | sed 's/"//g'`
parent_resource_id=`aws apigateway get-resources --rest-api-id ${api_id} | jq '.items[0].id' | sed 's/"//g'`
## Create resource (endpoint uri)
resource_id=`aws apigateway create-resource --rest-api-id ${api_id} --parent-id ${parent_resource_id} --path-part ${aws_lambda_func_name} | jq .id | sed 's/"//g'`

## Create http method in specified resource (GET, POST, PUT, ...etc)
aws apigateway put-method \
    --rest-api-id ${api_id} \
    --resource-id ${resource_id} \
    --http-method POST \
    --authorization-type NONE \
    > /dev/null

## apigatewayのintegration uriについて
## c.f. https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-apitgateway-method-integration.html
aws apigateway put-integration \
    --rest-api-id ${api_id} \
    --resource-id ${resource_id} \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${func_arn}/invocations \
    > /dev/null

## API GatewayからLambdaを実行するためのリソースポリシーを設定する
lambda_statement_id=`od -vAn -N16 -tx < /dev/urandom | sed 's/ //g'`    # create statement id randomly
aws lambda add-permission \
    --function-name ${aws_lambda_func_name} \
    --statement-id ${lambda_statement_id} \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn arn:aws:execute-api:${aws_region}:${aws_id}:${api_id}/*/*/${aws_lambda_func_name} \
    > /dev/null

## Deploy API (stage: default)
aws apigateway create-deployment --rest-api-id ${api_id} --stage-name default > /dev/null

endpoint_uri=https://${api_id}.execute-api.${aws_region}.amazonaws.com/default/${aws_lambda_func_name}
echo "Endpoint: ${endpoint_uri}"
