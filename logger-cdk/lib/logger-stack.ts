import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import {LogGroup, RetentionDays } from 'aws-cdk-lib/aws-logs';
export class LoggerStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
   super(scope, id, props);
   const loggerFunction = new NodejsFunction(this, 'loggerFunction', {
      entry: '../logger-lambda/index.ts',
      handler: 'handler',
      environment: {
        POWERTOOLS_SERVICE_NAME: 'helloWorld',
        LOG_LEVEL: 'INFO',
      },
      logRetention: RetentionDays.ONE_WEEK,
    });

    new cdk.CfnOutput(this, 'LoggerFunction', {
      value: loggerFunction.functionName,
    });
  }
}
