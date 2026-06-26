import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    ec2 = boto3.client("ec2")
    instance_id = os.environ["INSTANCE_ID"]
    action = event.get("action", "")

    if action == "start":
        ec2.start_instances(InstanceIds=[instance_id])
        logger.info("Started %s", instance_id)
    elif action == "stop":
        ec2.stop_instances(InstanceIds=[instance_id])
        logger.info("Stopped %s", instance_id)
    else:
        logger.warning("Unknown action: %s", action)
