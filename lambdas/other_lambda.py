import json
import boto3

from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes.dynamo_db_stream_event import DynamoDBStreamEvent


alerts_queue_name = "alerts-queue"
sqs = boto3.client("sqs")


def handler(event: dict, context: LambdaContext):

    event = DynamoDBStreamEvent(event)
    alerts_queue_url = sqs.get_queue_url(QueueName=alerts_queue_name)['QueueUrl']

    for record in event.records:
        print(dict(record))
        sqs.send_message(MessageBody=json.dumps(record), QueueUrl=alerts_queue_url)
