module "roles" {
  source = "./modules/roles"
}

module "db" {
  source = "./modules/db"
}

module "lambda" {
  source = "./modules/lambda"
  iam_for_lambda_arn = module.roles.iam_for_lambda_arn
}

module "main" {
  source = "./modules/main"
  lambda_arn = module.lambda.lambda_arn
}
