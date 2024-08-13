usage:		    ## Shows usage for this Makefile
	@cat Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:        ## Install dependencies
	which awslocal || pip install awscli-local[ver1]
	which cdklocal || npm install -g aws-cdk-local aws-cdk
	cd tracer-lambda && npm install
	cd tracer-cdk && npm install
	cd logger-lambda && npm install
	cd logger-cdk && npm install
	cd metrics-lambda && npm install
	cd metrics-cdk && npm install
	cd idempotency-lambda && npm install
	cd idempotency-cdk && npm install
	cd parameters-lambda && npm install
	cd parameters-cdk && npm install

deploy-logger:         ## Deploy the app to LocalStack
	cd logger-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-tracer:         ## Deploy the app to LocalStack
	cd tracer-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-metrics:         ## Deploy the app to LocalStack
	cd metrics-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-idempotency:         ## Deploy the app to LocalStack
	cd idempotency-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-parameters:         ## Deploy the app to LocalStack
	cd parameters-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

invoke:
	awslocal lambda invoke --function-name "$(LAMBDA_NAME)" output.txt

invoke-logger:  ## Invoke the 'logger' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep Logger) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke-tracer:  ## Invoke the 'tracer' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep Tracer) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke-parameters:  ## Invoke the 'parameters' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep Parameters) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke-metrics:  ## Invoke the 'parameters' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep Metrics) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke-idempotency:  ## Invoke the 'parameters' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep Idempotency) && \
		LAMBDA_NAME=$$funcName PRODUCT_ID=1 make invoke-idempotency-params && \
		LAMBDA_NAME=$$funcName PRODUCT_ID=1 make invoke-idempotency-params && \
		LAMBDA_NAME=$$funcName PRODUCT_ID=2 make invoke-idempotency-params

invoke-idempotency-params:  ## Invoke the 'parameters' sample Lambda function locally
	awslocal lambda invoke --function-name "$(LAMBDA_NAME)" --payload '{ "productid": "$(PRODUCT_ID)", "user": "2" }' --cli-binary-format raw-in-base64-out --invocation-type RequestResponse output.txt

.PHONY: usage install deploy-logger deploy-tracer deploy-metrics deploy-parameters deploy-idempotency invoke-logger invoke-tracer invoke-metrics invoke-parameters invoke-idempotency invoke invoke-idempotency-params
