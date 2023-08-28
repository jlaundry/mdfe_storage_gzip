#!/bin/bash

rm -rf .env
python -m venv .env
source .env/bin/activate
pip install --upgrade pip

pip install \
    azure-functions \
    azure-storage-blob

pip freeze > requirements.txt
