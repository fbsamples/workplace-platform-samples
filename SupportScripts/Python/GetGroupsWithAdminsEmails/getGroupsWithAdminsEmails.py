#Demonstrates how to follow pagination to scroll through all group results with group name, admins, and emails
#This script requires the access token to be placed in a file named accessToken

import requests, os
import json, csv
import datetime

# Get the access token from a file named accessToken
def tokenFromFile():
    open("accessToken", "r")
    TOKEN = f.read()
    TOKEN = TOKEN.rstrip("\r\n")
    f.close()
    return TOKEN

# Initialize main vars
accessToken = os.environ.get('WP_ACCESS_TOKEN', None) or tokenFromFile() or 'replace_with_your_access_token'
VERBOSE = os.environ.get('VERBOSE', None) or False
SINCE = datetime.datetime.now()
apiHeaders = {'Content-Type': 'application/json'}
csvRows = []
GroupResults = []

# Get groups, base call
getGroups = "https://graph.workplace.com/community/groups?access_token=%s&fields=name" % accessToken
r = requests.get(getGroups, headers=apiHeaders)
response = r.json()

# Paginate through all groups
groups = response['data']
for group in groups:
   GroupResults.append(group)
paging = response['paging']
next = True
while next:
    try:
        url = paging['next']
        r = requests.get(url, headers=apiHeaders)
        answer = r.json()
        groups = answer['data']
        for group in groups:
            GroupResults.append(group)
        paging = answer['paging']
    except KeyError:
        next = False

# Iterate through all groups and get group admins
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
        csvRows.append(csvRow)

# Write CSV
csv_filename = "All Group Admins export - %s.csv" % SINCE.strftime("%Y-%m-%d %H-%M")
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
