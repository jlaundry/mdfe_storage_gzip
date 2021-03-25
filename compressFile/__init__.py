
import gzip
import logging
import io
import os

import azure.functions as func
from azure.storage.blob import BlobServiceClient, StandardBlobTier


def main(msg: func.QueueMessage, deletable: func.Out[str]) -> None:
    infilename = msg.get_body().decode('utf-8')
    logging.info(f"compressFile trigger processed a queue item: {infilename}")

    connection_string = os.getenv("MDfETelemetryStorage")
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    (container_name, blob_name) = infilename.split("/", 1)
    content = io.BytesIO()

    with blob_service_client.get_blob_client(container=container_name, blob=blob_name) as blob_client:
        with gzip.GzipFile(fileobj=content, filename=os.path.basename(infilename), mode='wb') as gzf:
            gzf.write(blob_client.download_blob().readall())

    content.seek(0)

    with blob_service_client.get_blob_client(container='archive', blob=f"{infilename}.gz") as blob_client:
        blob_client.upload_blob(content)
        # blob_client.set_standard_blob_tier(StandardBlobTier.Cool)

    # Flag original file for deletion
    deletable.set(infilename)
