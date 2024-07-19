#!/usr/bin/env python

# Simple script to transform generated CDK CloudFormation templates into self-contained
# CFn templates that can be deployed from a URL using our internal `/_localstack/cloudformation/deploy`
# CFn deployment UI in LocalStack. Note that this approach has some limitation, e.g., since we're
# embedding the base64-encoded bytes of , it can only

import base64
import sys
import yaml
from localstack.utils.files import load_file, save_file
from localstack.utils.strings import to_str
from localstack.services.cloudformation.engine.template_preparer import parse_template

# whether to transform the Code attribute in *all* functions in the
# template (to avoid CFn deployment errors with missing S3 buckets)
TRANSFORM_ALL_FUNCTIONS = True

LAMBDA_CREATOR_RESOURCE = "lambdaCreatorCustomResource"
LAMBDA_CREATOR_FUNC_NAME = "lambdaCreatorFunction"

# resources template
RESOURCES = """
  testBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: test
  lambdaCreatorCustomResource:
    Type: Custom::MyCustomResource
    Properties:
      ServiceToken: !GetAtt lambdaCreatorFunction.Arn
  lambdaCreatorFunction:
    Type: AWS::Lambda::Function
    Properties:
      Code:
        ZipFile: |
          import boto3, base64, urllib3, json

          def handler(event, context):
              zip_bytes_b64 = "<zip_bytes_b64>"
              zip_bytes = base64.b64decode(zip_bytes_b64)
              boto3.client("s3").put_object(Bucket="test", Key="lambda.zip", Body=zip_bytes)
              send(event, context, "SUCCESS", {})

          def send(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False, reason=None):
              http = urllib3.PoolManager()
              responseUrl = event['ResponseURL']
              print(responseUrl)
              responseBody = {
                  'Status' : responseStatus,
                  'Reason' : reason or "See the details in CloudWatch Log Stream: {}".format(context.log_stream_name),
                  'PhysicalResourceId' : physicalResourceId or context.log_stream_name,
                  'StackId' : event['StackId'],
                  'RequestId' : event['RequestId'],
                  'LogicalResourceId' : event['LogicalResourceId'],
                  'NoEcho' : noEcho,
                  'Data' : responseData
              }
              json_responseBody = json.dumps(responseBody)
              response = http.request('PUT', responseUrl, body=json_responseBody)
              print("Status code:", response.status)

      Handler: index.handler
      Role: !GetAtt lambdaCreatorFunctionRole.Arn
      Runtime: python3.9
      Timeout: 30
    DependsOn:
      - testBucket
  lambdaCreatorFunctionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Action: sts:AssumeRole
            Effect: Allow
            Principal:
              Service:
                - "lambda.amazonaws.com"
"""


def transform(template_file, func_resource_name, func_zip_file):
    template = load_file(template_file)
    template = parse_template(template)

    additional_resources = parse_template(RESOURCES)

    # insert new resources
    resources = template["Resources"]
    resources.update(additional_resources)

    # transform existing functions
    func_resources = {func_resource_name}
    if TRANSFORM_ALL_FUNCTIONS:
        func_resources = {key for key, item in resources.items() if item["Type"] == "AWS::Lambda::Function" and key != LAMBDA_CREATOR_FUNC_NAME}
    for func_resource in func_resources:
        transform_lambda(resources, func_resource)

    # insert base64 encoded Lambda zip file into template
    creator_func_code = resources["lambdaCreatorFunction"]["Properties"]["Code"]
    func_bytes = load_file(func_zip_file, mode="rb")
    func_bytes_b64 = to_str(base64.b64encode(func_bytes))
    creator_func_code["ZipFile"] = creator_func_code["ZipFile"].replace("<zip_bytes_b64>", func_bytes_b64)

    # drop some CDK boilerplate resources (e.g., bootstrap version) which are not required
    template.setdefault("Rules", {}).pop("CheckBootstrapVersion", None)
    template.setdefault("Parameters", {}).pop("BootstrapVersion", None)

    print('!final', template)
    template_file_final = template_file.replace(".yaml", ".transformed.yaml")
    save_file(template_file_final, yaml.dump(template))


def transform_lambda(resources: dict, func_resource_name: str):
    # update function
    func = resources[func_resource_name]
    func.setdefault("DependsOn", []).append(LAMBDA_CREATOR_RESOURCE)

    # update function code to use bucket with uploaded zip file
    func['Properties']['Code'] = {
        "S3Bucket": "test",
        "S3Key": "lambda.zip",
    }


def main():
    template_file = sys.argv[1]
    transform(template_file, sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <cfn_template_file> <lambda_resource_name> <lambda_zip_file>")
        sys.exit(1)
    main()
