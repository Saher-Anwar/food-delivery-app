resource "aws_dynamodb_table" "orders" {
  name = var.table_name
  hash_key = "_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "_id"
    type = "N"
  }
}