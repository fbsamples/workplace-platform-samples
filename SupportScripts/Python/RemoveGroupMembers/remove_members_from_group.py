# Copyright 2021-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
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
def removeMemberFromGroup(access_token, group_id, email):
    endpoint = GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX
    headers = buildHeader(access_token)
    data = {JSON_KEY_EMAIL: email}
    result = requests.delete(GRAPH_URL_PREFIX + group_id + MEMBERS_SUFFIX, headers=headers, data=data)
    return result

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-RemoveMembersGroup"}

# Example of creating a CSV of group members
#accessToken = raw_input('Enter your access token: ')
#groupId = raw_input('Enter your group ID: ')
#fileName = raw_input('Enter the name of the CSV file with the members emails: ')
accessToken = 'replace_with_access_token'
groupId = 'replace_with_group_id'
fileName = 'list_emails_of_members_to_remove.csv'

with open(fileName, newline='') as f:
    reader = csv.reader(f)
    for email in reader:
        result = removeMemberFromGroup(accessToken, groupId, email)
        print ('Removing ' + str(email) + ' -> ' + result.text)
