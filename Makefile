

start:
	localstack start -d

stop:
	localstack stop


provision:
	tflocal init
	tflocal apply --auto-approve


destroy:
	tflocal destroy --auto-approve
