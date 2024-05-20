# terraform for AWS or tflocal for localstack
terraform ?= terraform

start:
	localstack start -d

stop:
	localstack stop


provision:
	$(terraform) init
	$(terraform) apply --auto-approve


destroy:
	$(terraform) destroy --auto-approve


name =

plan_module:
	$(terraform) init && \
	$(terraform) plan -target=module.$(name)


provision_module:
	$(terraform) init && \
	$(terraform) apply --auto-approve -target=module.$(name)


destroy_module:
	$(terraform) init && \
	$(terraform) destroy --auto-approve -target=module.$(name)
