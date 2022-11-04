import requests
import csv

# Constants
GRAPH_URL_PREFIX = 'https://graph.facebook.com/'

# Variables
access_token = ''
file_name = 'ids_of_archived_groups.csv'

# Methods
def sendUnarchiveRequest(access_token, endpoint):
    headers = buildHeader(access_token)
    result = requests.post(endpoint, headers=headers)
    result_console = endpoint + ' unarchiving group' + ' -> ' + result.text
    print (result_console)

def buildHeader(access_token):
    return {'Authorization': 'Bearer ' + access_token, "User-Agent": "GithubRep-Unarchivegroups"}

def unarchiveGroup(access_token, group_id):
    endpoint  = GRAPH_URL_PREFIX + group_id + '?archive=false' 
    sendUnarchiveRequest(access_token, endpoint)

## START

with open(file_name, newline='') as f:
    reader = csv.reader(f)
    next(reader) #Skip header
    for row in reader:
        unarchiveGroup(access_token, row[0])
