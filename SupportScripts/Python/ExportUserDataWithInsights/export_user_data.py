# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json
import time

# Constants
GRAPH_URL_PREFIX = 'https://graph.workplace.com/'
EXPORT_SUFFIX = '/export_employee_data'
COMMUNITY_SUFFIX = 'community'
JSON_KEY_DATA = 'data'
JSON_KEY_PAGING = 'paging'
JSON_KEY_NEXT = 'next'

# Methods
def programUserDataFileExport(access_token):
    endpoint  = GRAPH_URL_PREFIX + COMMUNITY_SUFFIX + EXPORT_SUFFIX
    return getJobId(access_token, endpoint)

def getExportFileUrl(access_token, job_id):
    endpoint  = GRAPH_URL_PREFIX + job_id
    job_status = ""
    while ("COMPLETED" != job_status and "FAILED" != job_status):
        time.sleep(5)
        job_data = getJobData(access_token, endpoint)
        job_status = job_data.get('status')
        print ("Retrying. Job Status: " + job_status)
    if ("FAILED" != job_status):
        return job_data.get('result')
    else:
        return job_status

def getJobId(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.post(endpoint,headers=headers)
    result_json = json.loads(result.text)
    return result_json.get('id')

def getJobData(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.get(endpoint,headers=headers)
    result_json = json.loads(result.text)
    return result_json

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-ExportUserData"}

def downloadFile(file_url):
    result = requests.get(file_url)
    with open('export_user_data_file.xlsx', 'wb') as file:
        file.write(result.content)


## START
access_token = 'access_token'

print ("STARTING. Programing Export Job...")
job_id = programUserDataFileExport(access_token)
print ("Job Programmed. ID: " + job_id)
print ("Retrieving export file...")
file_url = getExportFileUrl(access_token, job_id)
try:
    downloadFile(file_url)
    print ("Export file successfully downloaded!")
except:
    print ("Export file url to download: " + file_url)
