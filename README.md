## Powertools for AWS Lambda (TypeScript) in LocalStack

[Powertools for AWS Lambda](https://docs.powertools.aws.dev/lambda/typescript/latest/) provide implementations of best practices for Lambda function development that are easy to integrate into your existing Lambda functions.

This examples repository provides basic examples of the TypeScript implementation Powertools that can be run and tested in [LocalStack](https://localstack.cloud). The good news is that Powertools (including the logger, metrics, parameters, tracer and idempotency shown here) can be used "out of the box" in LocalStack.

### Setup, Deployment and Testing the Examples

The easiest way to test these examples is to use the provided Makefile. Start by installing the necessary dependencies:

```bash
make install
```

Ensure that you have LocalStack running on your machine and then run the deploy command for the example you wish to run. For example:

```bash
make deploy-idempotency
```

Once the deployment is finished, invoke the Lambda function. For example:

```bash
make invoke-idempotency
```

### Manually Setup, Deployment and Testing the Examples

The examples are set up to enable easy deployment and testing of the particular Powertool library you wish to use. Each example has a lambda folder containing the example Lambda and a CDK folder containing the CDK script needed to deploy the example. You will need the AWS CLI, AWS CDK CLI, LocalStack, `awslocal` and `cdklocal` installed.

You'll need to run npm install within the directories for the example you wish to run. For instance:

```bash
cd tracer-lambda
npm install
cd ../tracer-cdk
npm install
```

Next, you can bootstrap and deploy using LocalStack's CDK wrapper from within the CDK folder for the example you wish to deploy to LocalStack.

```bash
cdklocal bootstrap
cdklocal deploy
```

The output will include the names of the deployed functions, which you can test using `awslocal` (replacing `TracerStack-tracerFunction` with the outputted function name):

```bash
awslocal lambda invoke --function-name TracerStack-tracerFunction output.txt
```
Note that the idempotency example does require passing a JSON payload containing a `productId` and `customer` (see the Makefile for an example on how to call this function manually).