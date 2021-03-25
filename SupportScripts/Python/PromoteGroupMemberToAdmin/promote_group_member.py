
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
GRAPH_URL_SLASH_SEP = '/'
GRAPH_URL_ADMINS_PARAM = '/admins'

# Methods
def sendModificationRequest(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.post(endpoint, headers=headers)
    print (endpoint + ' promoting member to admin in group -> ' + result.text)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-PromoteGroupAdmin"}

def modifyGroupAdmin(access_token, group_id, member_user_id):
    endpoint  = GRAPH_URL_PREFIX + group_id + GRAPH_URL_ADMINS_PARAM + GRAPH_URL_SLASH_SEP + member_user_id
    sendModificationRequest(access_token, endpoint)



## START
access_token = 'replace_with_your_access_token'
file_name = 'group_admin_change.csv'


with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        modifyGroupAdmin(access_token, row[0], row[1])
