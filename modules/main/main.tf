resource "aws_s3_bucket" "test-bucket" {
  bucket = "fkudi-some-my-awesome-bucket-123"
  force_destroy = true
}

# allow the s3 bucket to invoke the lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.test-bucket.arn
}


# create the bucket notification from s3 -> lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.test-bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_arn
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
          "ArnEquals": { "aws:SourceArn": "${var.lambda_arn}" }
        }
      }
    ]
  }
  POLICY
}
