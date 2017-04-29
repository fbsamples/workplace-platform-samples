# Copyright 2017-present, Facebook, Inc.
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
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods
def getAllGroups(access_token, community_id):
    endpoint  = GRAPH_URL_PREFIX + community_id + GROUPS_SUFFIX + FIELDS_CONJ + GROUP_FIELDS
    return getPagedData(access_token, endpoint, [])

def getAllMembers(access_token, community_id):
    endpoint  = GRAPH_URL_PREFIX + community_id + MEMBERS_SUFFIX + FIELDS_CONJ + MEMBER_FIELDS
    return getPagedData(access_token, endpoint, [])

def getGroupMembers(access_token, group_id):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX + FIELDS_CONJ + MEMBER_FIELDS
    return getPagedData(access_token, endpoint, [])

def addMemberToGroup(access_token, group_id, email):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX 
    headers = buildHeader(access_token)
    data = {JSON_KEY_EMAIL: email}
    result = requests.post(GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def removeMemberFromGroup(access_token, group_id, email):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX 
    headers = buildHeader(access_token)
    data = {JSON_KEY_EMAIL: email}
    result = requests.delete(GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def createNewGroup(access_token, name, description, privacy, administrator=None):
    headers = buildHeader(access_token)
    data = {
        "name": name,
        "description": description,
        "privacy": privacy,
        "admin": administrator
    }
    result = requests.post(GRAPH_URL_PREFIX + community_id + GROUPS_SUFFIX, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def getPagedData(access_token, endpoint, data):
    headers = buildHeader(access_token)
    result = requests.get(endpoint,headers=headers)
    result_json = json.loads(result.text, result.encoding)
    json_keys = result_json.keys()
    if JSON_KEY_DATA in json_keys and len(result_json[JSON_KEY_DATA]):
        data.extend(result_json[JSON_KEY_DATA])
    if JSON_KEY_PAGING in json_keys and JSON_KEY_NEXT in result_json[JSON_KEY_PAGING]:
        next = result_json[JSON_KEY_PAGING][JSON_KEY_NEXT]
        if next:
            getPagedData(access_token, next, data)
    return data

def getUserIDFromEmail(access_token, community_id, email):
    members = getAllMembers(access_token, community_id)
    for member in members:
        if "email" in member and member["email"] == email:
            return member["id"]
    return None

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}

# Example of creating a CSV of group members
access_token = raw_input('Enter your access token: ') 
community_id = raw_input('Enter your community ID: ')
groupid = raw_input('Enter your group ID: ')
grouplist = getGroupMembers(access_token, group_id)

# Example of creating a new group and adding an admin by email
#access_token = raw_input('Enter your access token: ') 
#community_id = raw_input('Enter your community ID: ')
#name = raw_input('Choose a group name: ')
#description = raw_input('Choose a group description: ')
#privacy = raw_input('Specify a privacy level (CLOSED | OPEN | SECRET): ')
#administrator_email = raw_input('Specify an administrator by email: ')
#member_email = raw_input('Specify a member by email: ')
#administrator_id = getUserIDFromEmail(access_token, community_id, administrator_email)

#if administrator_id:
#    result = createNewGroup(access_token, name, description, privacy, administrator_id)
#    if "id" in result:
#        print "Group created with ID " + result["id"]
#    if "error" in result:
#        print "Error creating group: " + result["error"]["message"]
#    group_id = result["id"]
#    result = addMemberToGroup(access_token, group_id, member_email)
#    if result["success"]:
#        print member_email + " was added to the group"
#    else:
#        print "Error adding " + member_email + " to the group" 
