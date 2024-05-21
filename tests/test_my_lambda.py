import boto3
import pytest


@pytest.fixture(autouse=True)
def setup(mocker):
    mocker.patch.object(boto3, "client")
    mocker.patch.object(boto3, "resource")


def test_my_lambda(capsys):
    """
    Simple test to check boto3 mocks
    """
    from lambdas import my_lambda  # lazy import, to mock boto3 first
    my_lambda.handler({}, None)

    # check last print
    captured = capsys.readouterr().out.splitlines()
    assert captured[-1] == "invocation not triggered by an event"
