# Copyright 2020-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'
ARCHIVE_CONJ = '?archive=' 
TRUE_SUFFIX = 'true'


# Methods
def archiveGroup(access_token, group_id):
    headers = buildHeader(access_token)
    endpoint  = GRAPH_URL_PREFIX + group_id + ARCHIVE_CONJ + TRUE_SUFFIX
    result = requests.post(endpoint, headers=headers)
    return result.text

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token}


## START
access_token = 'access_token'
file_name = 'group_to_archive.csv'

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        print("Archiving group " + str(row[0]) + ". Result: " + archiveGroup(access_token, str(row[0])))
