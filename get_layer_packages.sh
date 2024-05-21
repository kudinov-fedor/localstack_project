#!/bin/bash

export PKG_DIR="lambda_layer/python/lib/python3.8/site-packages"

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

docker run  --rm -v "$(pwd)":/foo -w /foo \
       lambci/lambda:build-python3.8 pip install -r requirements-lambda.txt -t ${PKG_DIR}
