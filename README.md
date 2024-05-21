> pip install -r requirements.txt
> make start
> make provision
> awslocal s3 ls 


To run on AWS:
1. Update file common/provider.tf with Keys
2. make prepare_lambda_layer
3. make provision
4. make destroy


To create new module and test:
1. make create_module name=foo
2. make plan_module name=foo
3. make provision_module name=foo
4. make destroy_module name=foo

For testing
1. Create venv
2. make setup_env
3. make test
