# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
FIELDS_CONJ = '?fields='
CONVERSATIONS_SUFFIX = '/conversations'
MESSAGES_FIELDS = 'messages{created_time,message,to,from}'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods
def getMessagesData(access_token, member_id):
    endpoint  = GRAPH_URL_PREFIX + member_id + CONVERSATIONS_SUFFIX + FIELDS_CONJ + MESSAGES_FIELDS
    print (endpoint)
    return getPagedData(access_token, endpoint, [])

def getNotPagedData(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.get(endpoint,headers=headers)
    return json.loads(result.text)

def getPagedData(access_token, endpoint, data):
    headers = buildHeader(access_token)
    result = requests.get(endpoint,headers=headers)
    result_json = json.loads(result.text)
    json_keys = result_json.keys()
    if JSON_KEY_DATA in json_keys and len(result_json[JSON_KEY_DATA]):
        data.extend(result_json[JSON_KEY_DATA])
    if JSON_KEY_PAGING in json_keys and JSON_KEY_NEXT in result_json[JSON_KEY_PAGING]:
        next = result_json[JSON_KEY_PAGING][JSON_KEY_NEXT]
        if next:
            getPagedData(access_token, next, data)
    return data

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-ExportUserMessages"}

def exportToFile(message_list):
    with open('message_export.txt', 'a') as file:
        file.write(json.dumps(message_list))


## START
access_token = 'your_access_token'
member_id = 'user_or_bot_id'

data = getMessagesData(access_token, member_id)
print (data);
if data:
    exportToFile(data);
