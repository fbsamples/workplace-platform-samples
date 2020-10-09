
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
def sendModificationRequest(access_token, endpoint, new_email):
    headers = buildHeader(access_token)
    body = {'email': new_email}
    result = requests.post(endpoint, headers=headers, data = body)
    print (endpoint + ' changing to ' + new_email + ' -> ' + result.text)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}

def modifyUserEmail(access_token, old_email, new_email):
    endpoint  = GRAPH_URL_PREFIX + old_email
    sendModificationRequest(access_token, endpoint, new_email)



## START
access_token = 'replace_with_your_access_token'
file_name = 'email_list_change.csv'


with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        modifyUserEmail(access_token, row[0], row[1])
