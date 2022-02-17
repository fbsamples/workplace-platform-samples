
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
FIELDS_CONJ = '?fields='
USER_CONJ = '&user='
MESSAGES_SUFFIX = '/messages'
GROUP_CHAT_PREFIX = 't_'
MESSAGES_FIELDS = 'id,created_time,message,from'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods
def getMessagesData(access_token, group_chat_id, member_id):
    endpoint  = GRAPH_URL_PREFIX + GROUP_CHAT_PREFIX + group_chat_id + MESSAGES_SUFFIX + FIELDS_CONJ + MESSAGES_FIELDS + USER_CONJ + member_id
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
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-ExportUserMessagesFromGroup"}

def exportToFile(message_list):
    with open('message_export.txt', 'w') as file:
        file.write(json.dumps(message_list, separators=(',\n', ': ')))


## START
access_token = 'access_token'
member_id = 'member_id'
group_chat_id = 'group_id'

data = getMessagesData(access_token, group_chat_id, member_id)
print (data);
if data:
    exportToFile(data);
