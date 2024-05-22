import json
import requests
import boto3
import pytest


@pytest.fixture(autouse=True)
def requests_mock(mocker):
    mocker.patch.object(requests.api, "request")


@pytest.fixture(autouse=True)
def boto3_mock(mocker):
    mocker.patch.object(boto3, "client")
    mocker.patch.object(boto3, "resource")
    yield boto3_mock

    # tear down, explicitly reset mocks
    from lambdas.my_lambda import s3, sqs, dynamodb
    s3.reset_mock()
    sqs.reset_mock()
    dynamodb.reset_mock()


def test_my_lambda(capsys):
    """
    Simple test to check boto3 mocks
    """
    from lambdas import my_lambda  # lazy import, to mock boto3 first
    my_lambda.handler({}, None)

    # check last print
    captured = capsys.readouterr().out.splitlines()
    assert captured[-1] == "invocation not triggered by an event"


def test_my_lambda_2(capsys, mocker):
    """
    Check that alerts were fired with appropriate log levels
    """

    # at this moment mocked boto3 created mocks on lambda module level,
    # and we can continue their setup
    from lambdas.my_lambda import s3, sqs, dynamodb, handler

    # s3.get_object(Bucket=bucket, Key=key)["Body"].read() ->  b'abc'
    items = [{"timestamp": "foo", "cpu": 50},
             {"timestamp": "foo", "cpu": 90}]

    read_obj = mocker.MagicMock()
    read_obj.read.return_value = "\n".join(map(json.dumps, items)).encode()
    mocker.patch.object(s3, "get_object", return_value={"Body": read_obj})

    # -------------  test logic ------------------
    event = {
        "Records": [
            {"s3": {"bucket": {"name": "foo"},
                    "object": {"key": "some_key"}}}
        ]
    }

    handler(event, None)
    assert s3.get_object.call_count == 1
    assert s3.get_object.call_args == ((), {"Bucket": "foo", "Key": "some_key"})

    assert sqs.send_message.call_count == 2
    levels = [json.loads(kwargs["MessageBody"])["level"]
              for _, kwargs in sqs.send_message.call_args_list]
    assert levels == ["WARNING", "CRITICAL"]

    assert dynamodb.Table.return_value.update_item.call_count == 2
    assert dynamodb.Table.return_value.put_item.call_count == 2


def test_my_lambda_3(capsys, mocker):
    """
    Check that no alerts were fired
    """

    # at this moment mocked boto3 created mocks on lambda module level,
    # and we can continue their setup
    from lambdas.my_lambda import s3, sqs, dynamodb, handler

    # s3.get_object(Bucket=bucket, Key=key)["Body"].read() ->  b'abc'
    items = [{"timestamp": "foo", "cpu": 20},
             {"timestamp": "foo", "cpu": 30}]

    read_obj = mocker.MagicMock()
    read_obj.read.return_value = "\n".join(map(json.dumps, items)).encode()
    mocker.patch.object(s3, "get_object", return_value={"Body": read_obj})

    # -------------  test logic ------------------
    event = {
        "Records": [
            {"s3": {"bucket": {"name": "foo"},
                    "object": {"key": "some_key"}}}
        ]
    }

    handler(event, None)
    assert s3.get_object.call_count == 1
    assert s3.get_object.call_args == ((), {"Bucket": "foo", "Key": "some_key"})
    assert sqs.send_message.called is False
    assert dynamodb.Table.return_value.update_item.called is False
    assert dynamodb.Table.return_value.put_item.called is False
