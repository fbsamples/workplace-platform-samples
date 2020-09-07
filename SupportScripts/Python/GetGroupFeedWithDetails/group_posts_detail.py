
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'
FIELDS_CONJ = '?fields=' 
GROUPS_SUFFIX = '/groups'
GROUP_FIELDS = 'id,name,members,privacy,description,updated_time'
MEMBERS_SUFFIX = '/members'
MEMBER_FIELDS = 'email,id,administrator'
REACTIONS_SUFFIX = '/reactions'
SEENBY_SUFFIX = '/seen'
COMMENTS_SUFFIX = '/comments'
POSTS_SUFFIX = '/feed'
POST_FIELDS = 'id,from,updated_time,type,message,source,story,properties,permalink_url'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods
def getAllGroups(access_token, community_id):
    endpoint  = GRAPH_URL_PREFIX + community_id + GROUPS_SUFFIX + FIELDS_CONJ + GROUP_FIELDS
    return getPagedData(access_token, endpoint, [])

def getAllPostsFromGroup(access_token, group_id):
    endpoint  = GRAPH_URL_PREFIX + group_id + POSTS_SUFFIX + FIELDS_CONJ + POST_FIELDS
    return getPagedData(access_token, endpoint, [])

def getReactionsData(access_token, post_id):
    endpoint  = GRAPH_URL_PREFIX + post_id + REACTIONS_SUFFIX
    return getPagedData(access_token, endpoint, [])

def getSeenByData(access_token, post_id):
    endpoint  = GRAPH_URL_PREFIX + post_id + SEENBY_SUFFIX
    return getPagedData(access_token, endpoint, [])

def getCommentsData(access_token, post_id):
    endpoint  = GRAPH_URL_PREFIX + post_id + COMMENTS_SUFFIX
    return getPagedData(access_token, endpoint, [])

def processGroupPosts(access_token, group_data):
    post_list = getAllPostsFromGroup(access_token, group_data['id'])
    if post_list:
        for idx,post in enumerate(post_list):
            post['group_name'] = group_data['name']
            post['reactions'] = getReactionsData(access_token, post['id'])
            post['comments'] = getCommentsData(access_token, post['id'])
            post['seenby'] = getSeenByData(access_token, post['id'])
            post_list[idx] = post
    return post_list

def getGroupData(access_token, group_id):
    endpoint  = GRAPH_URL_PREFIX + group_id + FIELDS_CONJ + GROUP_FIELDS
    return getNotPagedData(access_token, endpoint)

def getGroupMembers(access_token, group_id):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX + FIELDS_CONJ + MEMBER_FIELDS
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
    return {'Authorization': 'Bearer ' + access_token}


## START
access_token = 'your_access_token'
group_ids = ['group_id_1','group_id_2','group_id_3']

for group_id in group_ids:
    group_data = getGroupData(access_token, group_id)
    data = processGroupPosts(access_token, group_data)
    print (data);
