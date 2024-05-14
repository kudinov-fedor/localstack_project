resource "aws_s3_bucket" "test-bucket" {
  bucket = "fkudi-terraform-test-bucket"
  force_destroy = true
}


# create an IAM role for the lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  # todo add accesses to IAM role
  #  AmazonS3FullAccess
  # AmazonSQSFullAccess
  # AWSLambdaBasicExecutionRole
  # AWSXRayDaemonWriteAccess

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
