import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

def lambda_handler(event, context):
  data = table.scan()
  return data['Items']