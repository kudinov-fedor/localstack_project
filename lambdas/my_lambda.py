import json
import pytest
import requests
import boto3
from aws_lambda_powertools.utilities.data_classes import S3Event
from aws_lambda_powertools.utilities.typing import LambdaContext
# from aws_lambda_powertools.utilities.validation import validator


pytestmarks = pytest.mark.allow_hosts(['185.15.59.224'])  # allow wikipedia host


# configuration
alerts_queue_name = "alerts-queue"
table_name = "AlertsTable"

# AWS SDK clients
s3 = boto3.resource("s3")
sqs = boto3.resource("sqs")
dynamodb = boto3.resource('dynamodb')


# =============
# HELPER METHOD
# =============


def read_s3_object(event: S3Event) -> str:
    data = s3.get_object(Bucket=event.bucket_name,
                         Key=event.object_key)
    return data["Body"].read().decode("utf-8")


# ==============
# Lambda handler
# ==============


# @validator(inbound_schema=INPUT_SCHEMA, outbound_schema=OUTPUT_SCHEMA)
def handler(event: dict | S3Event, context: LambdaContext):

    event = S3Event(event)

    print("invoking function")
    print(requests.get("https://wikipedia.org"))

    import numpy as np
    import pandas as pd
    s = pd.Series([1, 3, 5, np.nan, 6, 8])
    print(s)

    if "Records" not in event:
        print("invocation not triggered by an event")
        return

    # resolve the queue to publish alerts to
    table = dynamodb.Table(table_name)
    alerts_queue_url = sqs.get_queue_url(QueueName=alerts_queue_name)['QueueUrl']
    log_content = read_s3_object(event)

    print("log content")
    print(log_content)

    # parse structured log records
    records = [json.loads(line) for line in log_content.split("\n") if line.strip()]
    alerts = []

    for record in records:
        # filter log records to create alerts
        try:
            alert = None

            if record['cpu'] >= 90:
                alert = {"timestamp": record['timestamp'], "level": "CRITICAL", "message": "Critical CPU utilization"}
            elif record['cpu'] >= 50:
                alert = {"timestamp": record['timestamp'], "level": "WARNING", "message": "High CPU utilization"}

            if alert:
                alerts.append(alert)
                sqs.send_message(MessageBody=json.dumps(alert), QueueUrl=alerts_queue_url)

                #  I add column 'count' with rowCount to existing first row,
                #  and receive it as return value result of update
                response = table.update_item(
                    Key={'id': '0'},
                    UpdateExpression="ADD #cnt :val",  # tech col to insert incremental index, to be used as latest
                    ExpressionAttributeNames={'#cnt': 'count'},
                    ExpressionAttributeValues={':val': 1},
                    ReturnValues="UPDATED_NEW"
                )

                nextId = response['Attributes']['count']
                print(repr(nextId))

                # Retrieve the new value
                alert = dict(alert)
                alert["id"] = str(nextId)

                print("alert", alert)
                table.put_item(Item=alert)

        except KeyError:
            pass
