module "roles" {
  source = "./modules/roles"
}

module "db" {
  source = "./modules/db"
}

module "main" {
  source = "./modules/main"
  iam_for_lambda_arn = module.roles.iam_for_lambda_arn
}
