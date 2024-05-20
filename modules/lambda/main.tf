data "archive_file" "lambda_layer" {
  type = "zip"
  output_path = "${path.cwd}/archives/lambda_layer.zip"
  source_dir = "${path.cwd}/lambda_layer"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = data.archive_file.lambda_layer.output_path
  layer_name = "lambda_layer_name"
  compatible_runtimes = ["python3.12"]
}


# helps to create zip with entrypoint file
data "archive_file" "lambda" {
  type = "zip"
  output_path = "${path.cwd}/archives/my_lambda.zip"
  source_file = "${path.cwd}/lambda/my_lambda.py"
}

# create the filter lambda
resource "aws_lambda_function" "func" {
  # instead of deploying the lambda from a zip file,
  # we can also deploy it using local code mounting
  filename      = data.archive_file.lambda.output_path
  function_name = "example_lambda_name"
  role          = var.iam_for_lambda_arn
  handler       = "my_lambda.handler"
  runtime       = "python3.12"
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}
