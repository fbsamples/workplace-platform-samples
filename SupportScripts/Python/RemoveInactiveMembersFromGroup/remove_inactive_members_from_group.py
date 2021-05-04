# Copyright 2021-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
FIELDS_CONJ = '?fields=' 
GROUPS_SUFFIX = '/groups'
GROUP_FIELDS = 'id,name,members,privacy,description,updated_time'
MEMBERS_SUFFIX = '/members'
MEMBER_FIELDS = 'id,email,administrator,active,account_claim_time'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods
def getGroupMembers(access_token, group_id):
    endpoint  = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX + FIELDS_CONJ + MEMBER_FIELDS
    return getPagedData(access_token, endpoint, [])

def checkIfMemberIsInactive(user):
    #print (user)
    # We consider them inactive if they are not group admins, and if they haven't claimed their account or they have been deactivated
    if (False == user['administrator'] and ('account_claim_time' not in user or False == user['active'])):
        return True
    else:
        return False

def removeMemberFromGroup(access_token, group_id, email):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX
    headers = buildHeader(access_token)
    data = {JSON_KEY_EMAIL: email}
    result = requests.delete(GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return result

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
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-RemoveInactiveMembersGroup"}

# Example of creating a CSV of group members
#accessToken = raw_input('Enter your access token: ') 
#groupId = raw_input('Enter your group ID: ')
accessToken = 'replace_with_access_token'
groupId = 'replace_with_group_id'

groupMembers = getGroupMembers(accessToken, groupId)
for member in groupMembers:
    if (checkIfMemberIsInactive(member)):
        result = removeMemberFromGroup(accessToken, groupId, member['email'])
        if ('email' in member):
            print ('Removing ' + member['email'] + ' from group -> ' + result.text)
        else:
            print ('Removing ' + member['id'] + ' from group -> ' + result.text)