locals {
  prefix = "terraform"
}

resource "aws_dynamodb_table" "users" {
  name = var.table_name
  hash_key = "_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "_id"
    type = "N"
  }
}

# Lambda Creation
# IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${local.prefix}_lambda_dynamodb_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.users.arn]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy_attachment" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy.json
}

# Package the Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function
resource "aws_lambda_function" "crud" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "lambda_handler"
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