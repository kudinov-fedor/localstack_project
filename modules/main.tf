resource "aws_s3_bucket" "test-bucket" {
  bucket = "${var.project}-bucket"
  force_destroy = true
}


# create an IAM role for the lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  # Trusted entities
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "test-attach-1" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach-2" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach-3" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "test-attach-4" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach-5" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


# create the filter lambda
resource "aws_lambda_function" "func" {
  # instead of deploying the lambda from a zip file,
  # we can also deploy it using local code mounting

  # works only for localstack, using filename instead
  #   s3_bucket = "__local__"
  #   s3_key    = "${path.cwd}/lambda"

  filename      = "lambda.zip"
  function_name = "example_lambda_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.handler"
  runtime       = "python3.10"
}


# allow the s3 bucket to invoke the lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.test-bucket.arn
}


# create the bucket notification from s3 -> lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.test-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}


# create the queue and give the lambda send access
resource "aws_sqs_queue" "test_queue" {
  name = "alerts-queue"

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "sqs:SendMessage",
        "Resource": "arn:aws:sqs:*:*:alerts-queue",
        "Condition": {
          "ArnEquals": { "aws:SourceArn": "${aws_lambda_function.func.arn}" }
        }
      }
    ]
  }
  POLICY
}


# addd dynamo db and seed data
resource "aws_dynamodb_table" "AlertsTable" {
  name           = "AlertsTable"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

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
