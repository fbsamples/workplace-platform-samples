# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json
import csv
from furl import furl
import os

# Constants
GRAPH_URL_BASE = 'https://graph.workplace.com/'

ADMIN_COL = 'admins'
COMMUNITY_COL = 'community'
FIELDS_CONJ = '?fields='
FIELDS_PARAM = 'fields'
GROUPS_COL = 'groups'
GROUP_FIELDS = 'id,name,members,privacy,description,updated_time'
GROUP_ALL_FIELDS = "id, name, description, privacy, joinable_by_non_members, join_settings, visibility, post_permission, archive, purpose, post_requires_admin_approval"
GROUP_ADMIN_FIELDS = 'id,first_name,last_name,email,title,department,employee_number,primary_phone,primary_address,picture,link,locale,name,name_format,updated_time'
MEMBERS_SUFFIX = '/members'
MEMBER_FIELDS = 'email,id,administrator'

JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'
JSON_KEY_EMAIL = 'email'

# Methods

## base methods
def urlBase():
    return furl(GRAPH_URL_BASE)

def buildHeader(accessToken):
    return {'Authorization': f'Bearer {accessToken}', "User-Agent": "GithubRep-BulkGroupCreation"}

def sendPayloadRequest(accessToken, endpoint, payload, log_msg):
    headers = buildHeader(accessToken)
    result = requests.post(endpoint, headers=headers, data = payload)
    return f'{endpoint} + {log_msg} + {result.text}'

def sendModificationRequest(accessToken, endpoint, log_msg):
    headers = buildHeader(accessToken)
    result = requests.post(endpoint, headers=headers)
    return f'{endpoint} + {log_msg} + {result.text}'

def getPagedData(accessToken, endpoint, data):
    headers = buildHeader(accessToken)
    result = requests.get(endpoint,headers=headers)
    result_json = json.loads(result.text)
    json_keys = result_json.keys()
    if JSON_KEY_DATA in json_keys and len(result_json[JSON_KEY_DATA]):
        data.extend(result_json[JSON_KEY_DATA])
    if JSON_KEY_PAGING in json_keys and JSON_KEY_NEXT in result_json[JSON_KEY_PAGING]:
        next = result_json[JSON_KEY_PAGING][JSON_KEY_NEXT]
        if next:
            getPagedData(accessToken, next, data)
    return data

## End Points

def getAllGroups(accessToken, community_id):
    uri = urlBase()
    uri.path.segments = [community_id, GROUPS_COL]
    return getPagedData(accessToken, uri.url, [])

def getCommunity(accessToken):
    uri = urlBase()
    uri.path.segments = [COMMUNITY_COL]
    headers = buildHeader(accessToken)
    result = requests.get(uri.url, headers=headers)
    return json.loads(result.text)

def createGroup(accessToken, payload):
    uri = urlBase()
    uri.path.segments = [COMMUNITY_COL, GROUPS_COL]
    headers = buildHeader(accessToken)
    result = requests.post(uri.url, headers=headers, data = payload)
    return f' Create group -> {result.text}'

def modifyGroupProperties(accessToken, group_id, properties = {}):
    log_msg = f'modifying group properties -> {group_id}'
    endpoint  = GRAPH_URL_BASE + group_id
    field_names = GROUP_ALL_FIELDS.split(', ')
    field_names.remove('id')
    filtered_properties = {k: v for k, v in properties.items() if k in field_names}
    sendPayloadRequest(accessToken, endpoint, filtered_properties, log_msg)


def addMemberToGroup(accessToken, group_id, email=None, userId=None):
    # endpoint = GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX
    headers = buildHeader(accessToken)
    uri = urlBase()
    uri.path.segments = [group_id, MEMBERS_SUFFIX]
    uri.args[JSON_KEY_EMAIL] = email
    endpoint = uri.tostr()
    # data = {JSON_KEY_EMAIL: email} # if (userId != None) else {JSON_KEY_USER_ID: userId}
    result = requests.post(endpoint, headers=headers) #, data=data)
    return json.loads(result.text)

def removeMemberFromGroup(accessToken, group_id, email):
    # endpoint = GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX
    uri = urlBase()
    uri.path.segments = [group_id, MEMBERS_SUFFIX]
    uri.args[JSON_KEY_EMAIL] = email
    endpoint = uri.tostr()
    headers = buildHeader(accessToken)
    # data = {JSON_KEY_EMAIL: email}
    result = requests.delete(endpoint, headers=headers) #, data=data)
    return json.loads(result.text)

def getGroupAdmin(accessToken, group_id):
    headers = buildHeader(accessToken)
    uri = urlBase()
    uri.path.segments = [group_id, ADMIN_COL]
    uri.args['fields'] = GROUP_ADMIN_FIELDS
    url = uri.tostr(query_dont_quote=True)
    result = requests.post(url, headers=headers)
    return json.loads(result.text)

def modifyGroupAdmin(accessToken, group_id, member_user_id, log_msg='promoting member to admin in group -> '):
    uri = urlBase()
    uri.path.segments = [group_id, ADMIN_COL, member_user_id]
    payload = {"uid": member_user_id}
    sendPayloadRequest(accessToken, uri.url, payload, log_msg)

def removeAdminsFromGroup(accessToken, groupId, adminsToRetain):
    groupAdmins = getGroupAdmin(accessToken, groupId)
    try:
        for admin in adminsToRetain:
            groupAdmins.remove(admin)
    except:
        None
    for email in groupAdmins:
        result = removeMemberFromGroup(accessToken, groupId, email)
        return f'Removing {str(email)} -> {result}'



def makeAdminPost(accessToken, group_id, member_user_id, message, log_msg=''):
    log_msg = f'archive group {group_id}'
    uri = urlBase()
    uri.path.segments = [group_id, 'feed']
    postPayload = {
        "message": message
    }
    sendPayloadRequest(accessToken, uri.url, postPayload, log_msg)


def getAllMembers(accessToken, community_id):
    uri = urlBase()
    uri.path.segments = [community_id, MEMBERS_SUFFIX]
    uri.args['fields'] = MEMBER_FIELDS
    url = uri.tostr(query_dont_quote=True)
    return getPagedData(accessToken, url, [])

def getUserIDFromEmail(accessToken, email):
    uri = urlBase()
    uri.path.segments = [email]
    result = requests.get(uri.url, headers=headers)
    return json.loads(result.text)['id']

def searchUserIDFromEmail(accessToken, community_id, email):
    members = getAllMembers(accessToken, community_id)
    for member in members:
        print(member)
        if "email" in member and member["email"] == email:
            return member["id"]
    return None


## loaders

def dedupeEntries(entries):
    seen = set()
    deduped = []
    for entry in entries:
        if entry not in seen:
            seen.add(entry)
            deduped.append(entry)
    return deduped

def load_modifyGroupAdmin(new_group_admins_file_name):
    with open(new_group_admins_file_name, newline='') as f:
        reader = csv.reader(f)
        for row in reader:
            modifyGroupAdmin(accessToken, row[0], row[1])

def load_createGroup(new_group_file_name):
    with open(new_group_file_name,  newline='') as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            payload = {
                "name":row[0],
                "description":row[1],
                "privacy":row[2],
                "join_setting":row[3],
                "post_permissions":row[4]

            }
            createGroup(accessToken, payload)

def load_groups(file_path):
    groups = []
    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        for row in reader:
            groups.append({'name': row[0], 'id': row[1]})
    return groups

def load_groupsWithMessage(file_path):
    groups = []
    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        next(reader)
        seen_ids = set()
        for row in reader:
            group_id = row[1]
            if group_id not in seen_ids:
                groups.append({'name': row[0], 'id': group_id, 'message': row[2]})
                seen_ids.add(group_id)
    return groups


## inits
accessToken = os.environ['WP_ACCESS_TOKEN'] or 'replace_with_your_access_token'

# new_group_admins_file_name = 'group_admin_change.csv'
# new_group_file_name = 'group_list.csv'

# groupId = 'replace_with_group_id'
groupsToArchiveFileName = os.environ['WP_GROUPS_TO_ARCHIVE_FILENAME'] or r'groups_to_archive.csv'
defaultArchivalMessage = 'This group is being archived.'

maintenanceAdminEmail = os.environ['WP_MAINT_ADMIN_EMAIL']

logs = []

## main steps

# Get list of all groups to be archived
## do you need to getAllGroups(accessToken, community_id)
# Assign the account “Workplace Team” (some_admin_email@your_company.com) as the admin for each group
# Post a message to all groups being archived
# Remove other admins from all groups being archived
# Archive all groups

community_id = getCommunity(accessToken)['id']
targetGroups = load_groupsWithMessage(groupsToArchiveFileName)
newAdminId = getUserIDFromEmail(accessToken, maintenanceAdminEmail)
for groupInfo in targetGroups:
    groupName, groupId, archivalMessage = groupInfo['name'], groupInfo['id'], groupInfo['message']
    archivalMessage = archivalMessage.strip() or defaultArchivalMessage
    logs.append( ['addMemberToGroup', groupId, newAdminId, addMemberToGroup(accessToken, groupId, newAdminId)] )
    logs.append( ['modifyGroupAdmin', groupId, newAdminId, modifyGroupAdmin(accessToken, groupId, newAdminId)] )
    logs.append( ['removeAdminsFromGroup', groupId, maintenanceAdminEmail, removeAdminsFromGroup(accessToken, groupId, [maintenanceAdminEmail])] )
    logs.append( ['makeAdminPost', groupId, newAdminId, makeAdminPost(accessToken, groupId, newAdminId, archivalMessage)] )
    logs.append( ['modifyGroupProperties', groupId, modifyGroupProperties(accessToken, groupId, {'archive': True})] )

print('\n\n')
print('Log of all actions taken:')
print(json.dumps(logs, indent=4))
