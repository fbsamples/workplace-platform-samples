
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'

# Methods
def sendModificationRequest(access_token, endpoint, frontline_status):
    headers = buildHeader(access_token)
    # Remove: , "has_access": "true" to only add users to Frontline set. Only permission 'Manage work profiles' is required.
    body = {"frontline": '{ "is_frontline": ' + frontline_status + ', "has_access": "true" }' }
    result = requests.post(endpoint, headers=headers, data = body)
    print (endpoint + ' changing frontline status to ' + frontline_status + ' -> ' + result.text)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}

def modifyUserFrontlineStatus(access_token, email, frontline_status):
    endpoint  = GRAPH_URL_PREFIX + email
    sendModificationRequest(access_token, endpoint, frontline_status)



## START
access_token = 'replace_with_your_access_token'
file_name = 'email_list_change.csv'


with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        modifyUserFrontlineStatus(access_token, row[0], row[1])
