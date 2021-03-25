
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import urllib
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'

# Methods
def sendModificationRequest(access_token, endpoint, group_description):
    headers = buildHeader(access_token)
    body = {'description': group_description}
    result = requests.post(endpoint, headers=headers, data=body)
    print (endpoint + ' updating description to ' + group_description + ' -> ' + result.text)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-UpdateGroupDescription"}

def modifyGroupDescription(access_token, group_id, group_description):
    endpoint  = GRAPH_URL_PREFIX + group_id
    sendModificationRequest(access_token, endpoint, group_description)



## START
access_token = 'replace_with_your_access_token'
file_name = 'group_description_change.csv'


with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        modifyGroupDescription(access_token, row[0], row[1])
