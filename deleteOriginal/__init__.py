
import logging
import os

import azure.functions as func
from azure.storage.blob import BlobServiceClient
# from azure.storage.blob import RetentionPolicy
        

def main(msg: func.QueueMessage) -> None:
    infilename = msg.get_body().decode('utf-8')
    logging.info(f"deleteOriginal trigger processed a queue item: {infilename}")

    connection_string = os.getenv("MDfETelemetryStorage")
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    # delete_retention_policy = RetentionPolicy(enabled=True, days=2)
    # blob_service_client.set_service_properties(delete_retention_policy=delete_retention_policy)

    (container_name, blob_name) = infilename.split("/", 1)
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_client.delete_blob()

    logging.info("Done.")
