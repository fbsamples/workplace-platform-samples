
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

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}

def reactivateUser(access_token, email):
    endpoint  = GRAPH_URL_PREFIX + email
    headers = buildHeader(access_token)
    body = {'active': True }
    result = requests.post(endpoint, headers=headers, data = body)
    print (endpoint + ' reactivating user -> ' + result.text)

## START
access_token = 'access_token'
file_name = 'email_list.csv'


with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        reactivateUser(access_token, row[0])
