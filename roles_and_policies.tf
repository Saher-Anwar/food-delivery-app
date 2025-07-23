# Policies
# Lambda
data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query", 
      "dynamodb:BatchWriteItem"
    ]
    resources = [aws_dynamodb_table.users.arn]
  }
}

data "aws_iam_policy" "DynamoDbReadOnly" {
  name = "AmazonDynamoDBReadOnlyAccess"
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy_attachment" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_readonly" {
  role = aws_iam_role.lambda_read_only.name
  policy_arn = data.aws_iam_policy.DynamoDbReadOnly.arn
}

# Roles
# Lambda
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

resource "aws_iam_role" "lambda_read_only" {
  name = "${local.prefix}_lambda_dynamodb_readonly_role"
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