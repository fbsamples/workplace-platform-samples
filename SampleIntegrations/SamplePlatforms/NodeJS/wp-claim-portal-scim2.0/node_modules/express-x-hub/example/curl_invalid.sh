#!/bin/bash

# Invalid X-Hub Post To http://0.0.0.0:3000/xhub
curl -i -H "content-type: application/json" -H "X-Hub-Signature: sha1=rubbish-signature" -H "content-length: 27" -H "transfer-encoding: chunked" -X POST -d "{ \"id\": \"realtime_update\" }" http://0.0.0.0:3000/xhub
