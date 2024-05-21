# terraform for AWS or tflocal for localstack
terraform ?= terraform

start:
	localstack start -d

stop:
	localstack stop


prepare_lambda_layer:
	rm -rf lambda_layer
	chmod +x get_layer_packages.sh
	./get_layer_packages.sh


provision:
	$(terraform) init
	$(terraform) apply --auto-approve


destroy:
	$(terraform) init
	$(terraform) destroy --auto-approve


name =

create_module:
	mkdir modules/$(name)
	ln -s ../../common/provider.tf modules/$(name)/provider.tf
	ln -s ../../common/common-variables.tf modules/$(name)/common-variables.tf
	touch modules/$(name)/main.tf
	echo "\nmodule \"$(name)\" {\n  source = \"./modules/$(name)\"\n}" >> main.tf


plan_module:
	$(terraform) init && \
	$(terraform) plan -target=module.$(name)


provision_module:
	$(terraform) init && \
	$(terraform) apply --auto-approve -target=module.$(name)


destroy_module:
	$(terraform) init && \
	$(terraform) destroy --auto-approve -target=module.$(name)
