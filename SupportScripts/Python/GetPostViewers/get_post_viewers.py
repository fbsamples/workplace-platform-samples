# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'
FIELDS_CONJ = '?fields=' 
SEEN_SUFFIX = '/seen'
USER_FIELDS = 'id,name,email,department,division,organization,title'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'

# Methods
def getPostSeenData(access_token, grouppost_id):
    endpoint  = GRAPH_URL_PREFIX + grouppost_id + SEEN_SUFFIX + FIELDS_CONJ + USER_FIELDS
    return getPagedData(access_token, endpoint, [])

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
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-PostViewers"}

def exportToCSV(user_list):
    keys = user_list[0].keys()
    with open('user_who_saw_the_post.csv', 'w', newline='\n')  as file:
        dict_writer = csv.DictWriter(file, fieldnames=keys, delimiter=',', quotechar='"', escapechar='\\', extrasaction='ignore')
        dict_writer.writeheader()
        dict_writer.writerows(user_list)


## START
access_token = 'access_token'
grouppost_id = 'groupid_postid'

post_data = getPostSeenData(access_token, grouppost_id)
print (post_data)

exportToCSV(post_data);
