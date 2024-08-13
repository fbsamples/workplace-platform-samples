# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

#Demonstrates how to follow pagination to scroll through all group results with group name, admins, and emails
#This script requires the access token to be placed in a file named accessToken

import requests, os
import json, csv
import datetime

# Initialize main vars
accessToken = os.environ.get('WP_ACCESS_TOKEN', None) or tokenFromFile() or 'enter_access_token_here'
VERBOSE = os.environ.get('VERBOSE', None) or False
SINCE = datetime.datetime.now()
apiHeaders = {'Content-Type': 'application/json'}
csv_filename = "All Group Admins export - %s.csv" % SINCE.strftime("%Y-%m-%d %H-%M")

# Get the access token from a file named accessToken
def tokenFromFile():
    return None if not os.path.exists("accessToken") else None
    f = open("accessToken", "r")
    TOKEN = f.read()
    TOKEN = TOKEN.rstrip("\r\n")
    f.close()
    return TOKEN

def groupsAllWithPagination():
    # Get groups, base call
    getGroups = f'https://graph.workplace.com/community/groups?access_token={accessToken}&fields=name'
    r = requests.get(getGroups, headers=apiHeaders)
    response = r.json()
    outputGroups = []

    # Paginate through all groups
    groups = response['data']
    for group in groups:
        outputGroups.append(group)
        paging = response['paging']
        next = True
        while next:
            try:
                url = paging['next']
                r = requests.get(url, headers=apiHeaders)
                answer = r.json()
                groups = answer['data']
                for group in groups:
                    outputGroups.append(group)
                paging = answer['paging']
            except KeyError:
                next = False
    return outputGroups

def collectGroupAdmins(GroupResults):
    # Iterate through all groups and get group admins
    csvRowsOutput = []
    for group in GroupResults:
        gi = group['id']
        gn = group['name']
        getGroup = "https://graph.workplace.com/%s/admins?&access_token=%s" % (gi, accessToken)
        r = requests.get(getGroup, headers=apiHeaders)
        response = r.json()
        admins = response['data']

        for admin in admins:
            adminID = admin['id']
            adminName = admin['name']
            getMember = "https://graph.workplace.com/%s?access_token=%s&fields=email" % (adminID, accessToken)
            r = requests.get(getMember, headers=apiHeaders)
            response = r.json()
            email = response.get('email') or ''
            csvRow = [gn, gi, adminName, email]
            csvRowsOutput.append(csvRow)
    return csvRowsOutput

def csvWrite(csvRows):
    # Write CSV
    print("Writing CSV File: %s" % csv_filename) if VERBOSE else None
    with open(csv_filename, "w") as csvfile:
        writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

        # CSV Header
        header = ["Group Name", "Group ID", "Admin Name", "email"]
        writer.writerow(header)
        writer.writerows(csvRows)
        print(csvRows) if VERBOSE else None

    # Wrapup
    print("CSV File Created: %s" % csv_filename)

# Run
GroupResults = groupsAllWithPagination()
csvRows = collectGroupAdmins(GroupResults)
csvWrite(csvRows)
