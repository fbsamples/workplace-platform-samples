# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
GRAPH_URL_SEPARATOR = '/'
GRAPH_URL_MEMBER_EDGE = 'members'
GRAPH_URL_EMAIL_FIELD = '?email='

# Variables
access_token = 'your_access_token'
group_id = 'your_group_id'
file_name = 'email_list.csv'

# Methods
def sendAdditionRequest(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.post(endpoint, headers=headers)
    result_console = endpoint + ' - adding user to group' + ' -> ' + result.text
    print (result_console)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-AddUsersToGroup"}

def addUserToGroup(access_token, group_id, email):
    endpoint  = GRAPH_URL_PREFIX + group_id + GRAPH_URL_SEPARATOR + GRAPH_URL_MEMBER_EDGE + GRAPH_URL_EMAIL_FIELD + email
    sendAdditionRequest(access_token, endpoint)


## START

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    next(reader) #Skip header
    for row in reader:
        addUserToGroup(access_token, group_id, row[0])
