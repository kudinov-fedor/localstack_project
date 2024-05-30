# create lambda layer based on existing folder
data "archive_file" "lambda_layer" {
  type = "zip"
  output_path = "${path.cwd}/archives/lambda_layer.zip"
  source_dir = "${path.cwd}/lambda_layer"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = data.archive_file.lambda_layer.output_path
  layer_name = "lambda_layer_name"
  compatible_runtimes = ["python3.8"]
}


# create the filter lambda
data "archive_file" "lambda" {
  type = "zip"
  output_path = "${path.cwd}/archives/my_lambda.zip"
  source_file = "${path.cwd}/lambdas/my_lambda.py"
}

resource "aws_lambda_function" "func" {
  # instead of deploying the lambda from a zip file,
  # we can also deploy it using local code mounting
  filename      = data.archive_file.lambda.output_path
  function_name = "my_lambda"
  role          = var.iam_for_lambda_arn
  handler       = "my_lambda.handler"
  runtime       = "python3.8"
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}


# one more lambda for dynamo db stream
data "archive_file" "other_lambda" {
  type = "zip"
  output_path = "${path.cwd}/archives/other_lambda.zip"
  source_file = "${path.cwd}/lambdas/other_lambda.py"
}

resource "aws_lambda_function" "other_lambda_func" {
  # instead of deploying the lambda from a zip file,
  # we can also deploy it using local code mounting
  filename      = data.archive_file.other_lambda.output_path
  function_name = "other_lambda"
  role          = var.iam_for_lambda_arn
  handler       = "other_lambda.handler"
  runtime       = "python3.8"
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}
