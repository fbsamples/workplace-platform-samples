
# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'

# Variables
access_token = 'replace_with_your_access_token'
file_name = 'email_list_change.csv'

# Methods
def sendModificationRequest(access_token, endpoint, frontline_status, has_access):
    headers = buildHeader(access_token)
    body = {"frontline": '{ "is_frontline": ' + frontline_status + ', "has_access":' + has_access + ' }' }
    result = requests.post(endpoint, headers=headers, data = body)
    print (endpoint + ' changing frontline status to ' + frontline_status + ' and has_access to ' + has_access + ' -> ' + result.text)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}

def modifyUserFrontlineStatus(access_token, email, frontline_status, has_access):
    endpoint  = GRAPH_URL_PREFIX + email
    sendModificationRequest(access_token, endpoint, frontline_status, has_access)



## START

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    next(reader) #Skip header
    for row in reader:
        #replace row[2] with string 'true' if not using 'has_access' column in csv.
        modifyUserFrontlineStatus(access_token, row[0], row[1], row[2])  
