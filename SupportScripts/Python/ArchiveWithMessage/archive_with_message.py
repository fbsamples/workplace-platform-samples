
# MIT license
# contributors: Zachary Jones

# using this file
# The file requires setting some variables before running.
# This can be done by att them to your terminal environemnt.
# In MacOS, this would be opening the terminal and typing
# ```
# export <variableName>=<value>
# ```
# related variable names are in ALL_CAPS, after each `os.environ`
# then run the script from that same terminal window
#
# reminder to run this script from a terminal, rather than double clicking on the file after updating code inline to include your own values
# the latter can result in the log output being lost, if the window auto-closes after completion.
#
# This script uses a CSV file as input. By dault, it's name should be groups_to_archive.csv
# The first row should contain column headers.
# The following rows should contain Group Name, Group ID, and the Message to send to the group as notification of its archival
# only group ids and messages will be used, the name is for human readability
# When the Message field is blank, a default archival message can be configured in the code below


import requests
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
def urlBase()
    return furl(GRAPH_URL_BASE)

def buildHeader(accessToken):
    return {'Authorization': 'Bearer ' + accessToken, "User-Agent": "GithubRep-BulkGroupCreation"}

def sendPayloadRequest(accessToken, endpoint, payload, log_msg):
    headers = buildHeader(accessToken)
    result = requests.post(endpoint, headers=headers, data = payload)
    return (endpoint + log_msg + result.text)

def sendModificationRequest(accessToken, endpoint, log_msg):
    headers = buildHeader(accessToken)
    result = requests.post(endpoint, headers=headers)
    return (endpoint + log_msg + result.text)

## End Points

def getAllGroups(access_token, community_id):
    uri = urlBase()
    uri.path.segments = [community_id, GROUPS_COL]
    return getPagedData(access_token, uri.url, [])

def getCommunity(accessToken):
    uri = urlBase()
    uri.path.segments = [COMMUNITY_COL]
    headers = buildHeader(accessToken)
    result = requests.post(uri.url, headers=headers)
    return (' Get community -> ' + result.text)

def createGroup(accessToken, payload):
    uri = urlBase()
    uri.path.segments = [COMMUNITY_COL, GROUPS_COL]
    headers = buildHeader(accessToken)
    result = requests.post(uri.url, headers=headers, data = payload)
    return (' Create group -> ' + result.text)

def modifyGroupProperties(access_token, group_id, properties = {}):
    endpoint  = GRAPH_URL_BASE + group_id
    field_names = GROUP_ALL_FIELDS.split(', ')
    field_names.remove('id')
    filtered_properties = {k: v for k, v in properties.items() if k in field_names}
    sendPayloadRequest(access_token, endpoint, filtered_properties)


def addMemberToGroup(access_token, group_id, email=None, userId=None):
    endpoint = GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX
    headers = buildHeader(access_token)
    data = (userId !== None) ? {JSON_KEY_USER_ID: userId} : {JSON_KEY_EMAIL: email}
    result = requests.post(GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def removeMemberFromGroup(access_token, group_id, email):
    endpoint = GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX
    headers = buildHeader(access_token)
    data = {JSON_KEY_EMAIL: email}
    result = requests.delete(GRAPH_URL_BASE + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def getGroupAdmin(accessToken, group_id):
    uri = urlBase()
    uri.path.segments = [group_id, ADMIN_COL]
    uri.args['fields'] = GROUP_ADMIN_FIELDS
    url = uri.tostr(query_dont_quote=True)
    result = requests.delete(url, headers=headers, data=data)
    return json.loads(result.text, result.encoding)

def modifyGroupAdmin(accessToken, group_id, member_user_id, log_msg):
    uri = urlBase()
    uri.path.segments = [group_id, ADMIN_COL, member_user_id]
    payload = {"uid": member_user_id}
    sendPayloadRequest(accessToken, uri.url, payload,' promoting member to admin in group -> ')

def removeAdminsFromGroup(accessToken, groupId, adminsToRetain=[maintenaceAdminEmail]):
    groupAdmins = getGroupAdmin(accessToken, groupId)
    try:
        for admin in adminsToRetain:
            existingAdmins.remove(admin)
    except:
        None
    for email in existingAdmins:
        result = removeMemberFromGroup(accessToken, groupId, email)
        return ('Removing ' + str(email) + ' -> ' + result.text)



def makeAdminPost(accessToken, group_id, member_user_id, message, log_msg):
    uri = urlBase()
    uri.path.segments = [group_id, 'feed']
    postPayload = {
        "message": message
    }
    sendPayloadRequest(accessToken, uri.url, log_msg, postPayload)


def getAllMembers(access_token, community_id):
    uri = urlBase()
    uri.path.segments = [community_id, MEMBERS_SUFFIX]
    uri.args['fields'] = MEMBER_FIELDS
    url = uri.tostr(query_dont_quote=True)
    return getPagedData(access_token, url, [])

def getUserIDFromEmail(access_token, community_id, email):
    members = getAllMembers(access_token, community_id)
    for member in members:
        if "email" in member and member["email"] == email:
            return member["id"]
    return None

def maintenanceAdminId(accessToken, community_id, maintenanceAdminEmail):
    return getUserIDFromEmail(accessToken, community_id, maintenanceAdminEmail)


## loaders

def dedupeEntries(entries):
    seen = set()
    deduped = []
    for entry in entries:
        if entry not in seen:
            seen.add(entry)
            deduped.append(entry)
    return deduped

def load_modifyGroupAdmin(new_group_admins_file_name)
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
        for row in reader:
            groups.append({'name': row[0], 'id': row[1], 'message': row[2]})
    return groups


## inits
accessToken = os.environ['WP_ACCESS_TOKEN'] or 'replace_with_your_access_token'

# new_group_admins_file_name = 'group_admin_change.csv'
# new_group_file_name = 'group_list.csv'

# groupId = 'replace_with_group_id'
groupsToArchiveFileName = os.environ['WP_GROUPS_TO_ARCHIVE_FILENAME'] or 'groups_to_archive.csv'
defaultArchivalMessage = 'This group is being archived.'

maintenaceAdminEmail = os.environ['WP_MAINT_ADMIN_EMAIL']

logs = []

## main steps

# Get list of all groups to be archived
## do you need to getAllGroups(accessToken, community_id)
# Assign the account “Workplace Team” (some_admin_email@your_company.com) as the admin for each group
# Post a message to all groups being archived
# Remove other admins from all groups being archived
# Archive all groups

community_id = getCommunity(accessToken)
targetGroups = load_groupsWithMessage(groupsToArchiveFileName)
newAdminId = maintenanceAdminId(accessToken, community_id, maintenanceAdminEmail)
dedupedTargetGroups = dedupeEntries(targetGroups)
for groupId, groupName, archivalMessage in dedupedTargetGroups:
    archivalMessage = archivalMessage.strip() or defaultArchivalMessage
    logs.append( addMemberToGroup(accessToken, groupId, newAdminId) )
    logs.append( modifyGroupAdmin(accessToken, groupId, newAdminId) )
    logs.append( removeAdminsFromGroup(accessToken, groupId) )
    logs.append( makeAdminPost(accessToken, groupId, newAdminId, archivalMessage) )
    logs.append( modifyGroupProperties(accessToken, groupId, {'archive': True}) )

print('\n\n')
print('Log of all actions taken:')
print(json.dumps(logs, indent=4))