# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
COMMUNITY_SUFFIX = 'community'
FIELDS_CONJ = '?fields='
GROUPS_SUFFIX = '/groups'
GROUP_FIELDS = 'id,name,admins{id,name,email},members.limit(0).summary(true),privacy,description,updated_time'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'

# Methods
def getAllGroups(access_token):
    endpoint  = GRAPH_URL_PREFIX + COMMUNITY_SUFFIX + GROUPS_SUFFIX + FIELDS_CONJ + GROUP_FIELDS
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

def processAdminsAndMembers(group_data):
    for idx, group in enumerate(group_data):
        group_data[idx]['members'] = group['members']['summary']['total_count']
        admins = ''
        try:
            for admin in group['admins']['data']:
                admins += admin['id'] + '-' + admin['name']
                try:
                    admins += ' (' + admin['email'] + ')|'
                except:
                    admins += '|'
            group_data[idx]['admins'] = admins
        except:
            return group_data
    return group_data

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-GroupsWithDetails"}

def exportToCSV(group_list):
    keys = group_list[0].keys()
    with open('group_export.csv', 'w', newline='\n')  as file:
        dict_writer = csv.DictWriter(file, fieldnames=keys, delimiter=',', quotechar='"', escapechar='\\', extrasaction='ignore')
        dict_writer.writeheader()
        dict_writer.writerows(group_list)


## START
access_token = 'access_token'

group_data = processAdminsAndMembers(getAllGroups(access_token))
print (group_data)

exportToCSV(group_data);
