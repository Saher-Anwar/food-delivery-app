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
  function_name    = "DyanmoDbCrud"
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
  function_name = "DynamoDbReadOnly"
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