locals {
  prefix = "terraform"
}

resource "aws_dynamodb_table" "users" {
  name = var.table_name
  hash_key = "_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "_id"
    type = "S"
  }
}

# Lambda Creation
# Package the Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/function.zip"
}

data "archive_file" "lambda_read_only" {
  type        = "zip"
  source_file = "${path.module}/lambda_read_only/handler.py"
  output_path = "${path.module}/lambda_read_only/function.zip"
}

resource "aws_lambda_function" "crud" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "Crud_DynamoDb"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.13"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }
}

resource "aws_lambda_function" "lambda_read_only" {
  filename = data.archive_file.lambda_read_only.output_path
  function_name = "GetUsers_DynamoDb"
  role = aws_iam_role.lambda_read_only.arn
  handler = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_read_only.output_base64sha256

  runtime = "python3.13"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "app" {
  name = "delivery-app-api"
  description = "REST Api for a delivery app"
  endpoint_configuration {
    types = [ "REGIONAL" ]
  }
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.app.id
  parent_id = aws_api_gateway_rest_api.app.root_resource_id
  path_part = "users"
}

# API Methods
resource "aws_api_gateway_method" "get_users" {
  rest_api_id = aws_api_gateway_rest_api.app.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_users" {
  rest_api_id = aws_api_gateway_rest_api.app.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = aws_api_gateway_method.get_users.http_method

  integration_http_method = "POST" # Always Post for Lambda
  type = "AWS_PROXY"
  uri = aws_lambda_function.lambda_read_only.invoke_arn
}

resource "aws_lambda_permission" "app" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_read_only.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.app.execution_arn}/*/*"
  depends_on = [ aws_lambda_function.lambda_read_only ]
}

# API Deployment Stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [ aws_api_gateway_integration.get_users ]

  rest_api_id = aws_api_gateway_rest_api.app.id
}

resource "aws_api_gateway_stage" "deployment" {
  stage_name = "dev"
  rest_api_id = aws_api_gateway_rest_api.app.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  description = "Development stage"
}