
from datetime import datetime, timezone, timedelta
import logging
import typing
import os
import json

import azure.functions as func
from azure.storage.blob import BlobServiceClient


def main(mytimer: func.TimerRequest, outqueue: func.Out[typing.List[str]]) -> None:

    start_time = datetime.utcnow().replace(tzinfo=timezone.utc)
    logging.info(f"Daily timer trigger started at {start_time.isoformat()} (pastdue:{mytimer.past_due})")
    queue_output = []

    connection_string = os.getenv("MDfETelemetryStorage")
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    day_ago = start_time - timedelta(days=2)
    skipped = 0

    for container in blob_service_client.list_containers():
        if not container.name.startswith("insights-logs"):
            logging.debug(f"skipping container {container.name}")
            continue

        logging.debug(f"working on container {container.name}")

        container_client = blob_service_client.get_container_client(container.name)
        for blob in container_client.list_blobs():
            if not blob.name.endswith(".json"):
                logging.debug(f"skipping {container.name}/{blob.name} (blob.name doesn't end with .json)")
                skipped += 1
            elif blob.last_modified > day_ago:
                logging.debug(f"skipping {container.name}/{blob.name} last_modified:{blob.last_modified}")
                skipped += 1
            else:
                msg = f"{container.name}/{blob.name}"
                queue_output.append(msg)
                continue

    outqueue.set(queue_output)
    end_time = datetime.utcnow().replace(tzinfo=timezone.utc)
    logging.info(f"Done, time:{(end_time - start_time)} queue_size:{len(queue_output)} skipped:{skipped}")
