
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
        if blob_client.exists():
            # File already exists, create a duplicate with id
            logging.warning(f"archive/{infilename}.gz already exists, attempting upload with duplicate ID")
            uploaded = False
            MAX_DUP_ATTEMPTS = 10

            for dup_id in range(1,MAX_DUP_ATTEMPTS):
                attempted_blob_name = f"{infilename}-DUPLICATE-{dup_id:0>3}.gz"
                with blob_service_client.get_blob_client(container='archive', blob=attempted_blob_name) as dup_blob_client:
                    if dup_blob_client.exists():
                        continue
                    else:
                        dup_blob_client.upload_blob(content)
                        logging.info(f"archive/{attempted_blob_name} uploaded")
                        # Flag original file for deletion
                        deletable.set(infilename)
                        uploaded = True
                        break

            if not uploaded:
                raise Exception(f"archive/{infilename}.gz already exists, MAX_DUP_ATTEMPTS reached")

        else:
            blob_client.upload_blob(content)
            # Flag original file for deletion
            deletable.set(infilename)

        # blob_client.set_standard_blob_tier(StandardBlobTier.Cool)
