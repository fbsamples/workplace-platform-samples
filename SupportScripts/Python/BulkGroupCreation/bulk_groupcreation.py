
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'

# Methods

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-BulkGroupCreation"}

def creategroup(access_token, payload):
    endpoint  = GRAPH_URL_PREFIX + '/community/groups'
    headers = buildHeader(access_token)
    result = requests.post(endpoint, headers=headers, data = payload)
    print (' Create group -> ' + result.text)

## START
access_token = 'access_token'
file_name = 'group_list.csv'


with open(file_name,  newline='') as f:
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
        print(row[0],row[1])
        print(payload)
        creategroup(access_token, payload)
