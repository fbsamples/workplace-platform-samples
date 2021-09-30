
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'

# Variables
access_token = 'your_access_token'
file_name = 'ids_of_users_to_delete.csv'

# Methods
def sendDeletionRequest(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.delete(endpoint, headers=headers)
    result_console = endpoint + ' deleting user' + ' -> ' + result.text
    print (result_console)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-DeleteUsers"}

def deleteUnclaimedUser(access_token, workplace_id):
    endpoint  = GRAPH_URL_PREFIX + workplace_id
    sendDeletionRequest(access_token, endpoint)

## START

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    next(reader) #Skip header
    for row in reader:
        deleteUnclaimedUser(access_token, row[0])
