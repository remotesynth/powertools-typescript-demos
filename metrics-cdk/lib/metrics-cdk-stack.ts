import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';

export class MetricsCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const metricsFunction = new NodejsFunction(this, 'metricsFunction', {
      entry: '../metrics-lambda/index.ts',
      handler: 'handler',
    });

    new cdk.CfnOutput(this, 'MetricsFunction', {
      value: metricsFunction.functionName,
    });
  }
}
