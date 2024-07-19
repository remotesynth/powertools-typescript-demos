usage:		    ## Shows usage for this Makefile
	@cat Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:        ## Install dependencies
	which awslocal || pip install awscli-local[ver1]
	which cdklocal || npm install -g aws-cdk-local aws-cdk
	cd tracer-lambda && npm install
	cd logger-lambda && npm install
	cd cdk && npm install

deploy-logger:         ## Deploy the app to LocalStack
	cd logger-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-tracer:         ## Deploy the app to LocalStack
	cd tracer-cdk && \
	    cdklocal bootstrap && \
	    cdklocal deploy --require-approval=never

deploy-cfn:     ## Deploy the generated CFn file to LocalStack
	awslocal cloudformation create-stack --stack-name test-stack --template-body file://./cdk/template.transformed.yaml

create-cfn-logger:     ## Create the self-contained CFn template for the logger function
	make synth
    # TODO: names below still need to be replaced / properly extracted by the script:
	utils/transform_template.py cdk/template.yaml loggerFunction1A496B16 cdk/cdk.out/.cache/3a099217b2db5213dc14e303b9b7c3b4a37b943738c18efd2129c8fc260dedc5.zip

invoke-logger:  ## Invoke the 'logger' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep logger) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke-tracer:  ## Invoke the 'tracer' sample Lambda function locally
	funcName=$$(awslocal lambda list-functions | jq -r '.Functions[].FunctionName' | grep tracer) && \
	    LAMBDA_NAME=$$funcName make invoke

invoke:
	awslocal lambda invoke --function-name "$(LAMBDA_NAME)" lambda-output.txt

synth:          ## Create the CFn template from the CDK stack
	cd cdk && cdklocal synth > template.yaml

.PHONY: usage install deploy invoke-logger invoke-tracer invoke synth
