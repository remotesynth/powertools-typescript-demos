This is an initial attempt to test Lambda Powertools for TypeScript running on LocalStack. Currently there are just two basic examples of the Logger and the Tracer.

You'll need to follow these steps to install all the dependencies before you can run this:

```bash
cd tracer-lambda
npm install
cd ../logger-lambda
npm install
cd ../cdk
npm install
```

Now you can bootstrap and deploy using LocalStack's CDK wrapper.

```bash
cdklocal bootstrap
cdklocal deploy
```

The output will include the names of the deployed functions, which you can test using `awslocal` (replacing `PowerToolsCdkStack-loggerFunction` with the outputted function name):

```bash
awslocal lambda invoke --function-name PowerTools-loggerFunction output.txt
```
At this point, the logger function output can be seen in CloudWatch. The tracer function just runs. Updating these with better examples soon.