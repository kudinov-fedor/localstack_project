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


plan:
	$(terraform) init
	$(terraform) plan


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


# unit testing
setup_env:
	python -m pip install -r requirements.txt
	python -m pip install -r requirements-lambda.txt

test:
	python -m pytest tests --disable-socket


# work around for windows as symlink not supported
update_commons:
	cp -r --remove-destination common/* modules/db
	cp -r --remove-destination common/* modules/roles
	cp -r --remove-destination common/* modules/main
	cp -r --remove-destination common/* modules/lambda
