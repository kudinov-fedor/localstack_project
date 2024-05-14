

start:
	localstack start -d

stop:
	localstack stop


provision:
	tflocal init  # first run
	tflocal apply
