# mdfe_storage_gzip

An Azure Function to gzip Microsoft Defender for Endpoint (MDfE) archive content in Storage accounts.


## Developing

Create a `local.settings.json` like so (replacing the Azurite connection string as appropriate):

```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "MDfETelemetryStorage": "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
  }
}
```

To trigger the daily timer task, send a POST request:

```bash
curl -X POST -H "Content-Type: application/json" -d '{}' http://localhost:7071/admin/functions/daily
```
