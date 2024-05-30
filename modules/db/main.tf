# addd dynamo db and seed data
resource "aws_dynamodb_table" "AlertsTable" {
  name           = "AlertsTable"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  billing_mode     = "PROVISIONED"
  stream_view_type = "NEW_IMAGE"
  stream_enabled   = true

  attribute {
    name = "id"
    type = "S"
  }
}

# create some seed data
resource "aws_dynamodb_table_item" "seed_data" {
  table_name = aws_dynamodb_table.AlertsTable.name
  hash_key   = aws_dynamodb_table.AlertsTable.hash_key

  for_each = {
      "0" = {
          level = "WARN"
          timestamp = "2022-10-12 23:12:52.453233"
          message = "Some warning"
      }
     "1" = {
          level = "ERROR"
          timestamp = "2023-09-17 17:12:22.676858"
          message = "Some error"
      }
  }
  item = <<ITEM
  {
    "id": {"S": "${each.key}"},
    "level": {"S": "${each.value.level}"},
    "timestamp": {"S": "${each.value.timestamp}"},
    "message": {"S": "${each.value.message}"},
    "count": {"N": "1"}
  }
  ITEM
}
