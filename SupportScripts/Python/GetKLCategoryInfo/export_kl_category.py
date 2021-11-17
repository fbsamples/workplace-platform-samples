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
SUBCAT_PREFIX = '/subcategories'
CATEGORY_FIELDS = 'id,title,content,status,read_audience,json_content,last_editor,last_updated'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'

# Methods
def getCategoryDataById(access_token, id):
    endpoint  = GRAPH_URL_PREFIX + id + FIELDS_CONJ + CATEGORY_FIELDS
    print (endpoint)
    category_data = getNotPagedData(access_token, endpoint)
    category_data['subcategories'] = getSubcategories(access_token, id)
    for subcat in category_data['subcategories']:
        subcat['subcategories'] = getCategoryDataById(access_token, subcat['id'])
    return category_data

def getSubcategories(access_token, id):
    endpoint  = GRAPH_URL_PREFIX + id + SUBCAT_PREFIX + FIELDS_CONJ + CATEGORY_FIELDS
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
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-KLCategoryData"}

def exportToFile(category_data):
    f = open('category_data.txt', 'w')
    f.write(json.dumps(category_data))
    f.close()


## START
access_token = 'access_token'
category_id = 'kl_cat_id'

category_data = getCategoryDataById(access_token, category_id)
#print (category_data)

exportToFile(category_data)
