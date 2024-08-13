# Copyright (c) Meta Platforms, Inc. and affiliates.
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
file_name = 'email_list_change.csv'

# Methods
def sendModificationRequest(access_token, endpoint, frontline_status, has_access):
    headers = buildHeader(access_token)
    if ('' != has_access):
        body = {"frontline": '{ "is_frontline": ' + frontline_status + ', "has_access": ' + has_access + ' }' }
    else:
        body = {"frontline": '{ "is_frontline": ' + frontline_status + ' }' }
    result = requests.post(endpoint, headers=headers, data = body)
    result_console = endpoint + ' changing frontline status to ' + frontline_status
    if ('' != has_access):
        result_console += ' and has_access to ' + has_access + ' -> ' + result.text
    result_console += ' -> ' + result.text
    print (result_console)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-UpdateFrontlineStatus"}

def modifyUserFrontlineStatus(access_token, email, frontline_status, has_access=''):
    endpoint  = GRAPH_URL_PREFIX + email
    sendModificationRequest(access_token, endpoint, frontline_status, has_access)



## START

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    next(reader) #Skip header
    for row in reader:
        #replace row[2] with string 'true' or empty string if not using 'has_access' column in csv.
        modifyUserFrontlineStatus(access_token, row[0], row[1], row[2])
