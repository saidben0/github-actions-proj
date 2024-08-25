import boto3
import json

def lambda_handler(event, context):
    # this is printed in the function's logs
    print(json.dumps(event))

    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }

    # return json.dumps('Hello from Lambda!')
