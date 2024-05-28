
data "aws_iam_policy_document" "lambda_policy" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


# create an IAM role for the lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json  # Trusted entities
}

# s3 read only
data "aws_iam_policy_document" "s3_read_policy" {
  version = "2012-10-17"

  statement {
    actions = ["s3:Get*",
               "s3:List*",
               "s3:Describe*",
               "s3-object-lambda:Get*",
               "s3-object-lambda:List*"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3_read_policy"
  description = "s3 read policy"
  policy = data.aws_iam_policy_document.s3_read_policy.json
}


# sqs write only
data "aws_iam_policy_document" "sqs_write_policy" {
  version = "2012-10-17"

  statement {
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_write_policy" {
  name        = "sqs_write_policy"
  description = "sqs write policy"
  policy = data.aws_iam_policy_document.sqs_write_policy.json
}

# dynamodb create only
data "aws_iam_policy_document" "dynamo_db_create_policy" {
  version = "2012-10-17"

  statement {
    actions = ["dynamodb:PutItem",
               "dynamodb:UpdateItem"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dynamo_db_create_policy" {
  name        = "dynamo_db_create_policy"
  description = "dynam db create policy"
  policy = data.aws_iam_policy_document.dynamo_db_create_policy.json
}


# attach policies
resource "aws_iam_role_policy_attachment" "test-attach-1" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "test-attach-2" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = aws_iam_policy.sqs_write_policy.arn
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
  policy_arn = aws_iam_policy.dynamo_db_create_policy.arn
}
