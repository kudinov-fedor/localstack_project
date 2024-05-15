import json

import boto3

# configuration
alerts_queue_name = "alerts-queue"
table_name = "AlertsTable"

# AWS SDK clients
s3 = boto3.client("s3")
sqs = boto3.client("sqs")
dynamodb = boto3.resource('dynamodb')


# =============
# HELPER METHOD
# =============


def read_s3_object(bucket, key) -> str:
    data = s3.get_object(Bucket=bucket, Key=key)
    return data["Body"].read().decode("utf-8")


def read_changed_object(event) -> str:
    s3_event = event["Records"][0]["s3"]
    bucket = s3_event["bucket"]["name"]
    key = s3_event["object"]["key"]

    return read_s3_object(bucket, key)


# ==============
# Lambda handler
# ==============


def handler(event, context):
    print("invoking function")

    if "Records" not in event:
        print("invocation not triggered by an event")
        return

    # resolve the queue to publish alerts to
    table = dynamodb.Table(table_name)
    alerts_queue_url = sqs.get_queue_url(QueueName=alerts_queue_name)['QueueUrl']
    log_content = read_changed_object(event)

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
                    UpdateExpression="ADD #cnt :val",
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
