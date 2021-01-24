
import gzip
import logging
import io
import os

import azure.functions as func


def main(msg: func.QueueMessage, infile: func.InputStream, outfile: func.Out[func.InputStream], deletable: func.Out[str]) -> None:
    infilename = msg.get_body().decode('utf-8')
    logging.info(f"compressFile trigger processed a queue item: {infilename}")

    # Cannot write directly to outfile, because func.InputStream doesn't have a .write() method
    content = io.BytesIO()
    
    with gzip.GzipFile(fileobj=content, filename=os.path.basename(infilename), mode='wb') as gzf:
        gzf.write(infile.read())

    content.seek(0)
    outfile.set(content)

    # Flag original file for deletion
    deletable.set(infilename)
