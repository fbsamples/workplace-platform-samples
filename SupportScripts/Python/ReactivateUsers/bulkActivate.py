#Reactivate a user if they have been deactivated based upon their userName
#This script requires the access token to be placed in a file named accessToken
#The script also requires a list Workplace user names in a file named userNames
#The format of userNames is to have 1 user name per line with no empty lines
import requests, json

#Get the access token from a file named accessToken
f = open("accessToken", "r")
TOKEN = f.read()
TOKEN = TOKEN.rstrip("\r\n")
f.close()
#Generate the Authentication header
AUTH = "Bearer %s" % TOKEN
headers = {'Authorization': AUTH, 'Content-Type': 'application/json'}

#Get the list of userNames
with open("userNames.csv", "r") as f:
    users = []
    for line in f:
        users.append(line.rstrip("\r\n"))
#print(users)

getUsers = "https://www.workplace.com/scim/v1/Users/"
r = requests.get(getUsers, headers=headers)
answer = r.json()
people = answer['Resources']
try:
    itemsPerPage = answer['itemsPerPage']
    total = answer['totalResults']
    startIndex = answer['startIndex']
    startIndex += itemsPerPage
    while startIndex < total:
        startIndex += itemsPerPage
        getUsers = "https://www.workplace.com/scim/v1/Users?count=%s&startIndex=%s&access_token=%s&appsecret_proof=%s&appsecret_time=%s" % (itemsPerPage, startIndex, TOKEN, appsecret_proof, t)
        r = requests.get(getUsers, headers=headers)
        answer = r.json()
        try:
            people = people + answer['Resources']
        except:
            x = 0
except:
    x = 0

xlink = {}
for person in people:
    try:
        if person['userName'] == '':
            xlink[person['externalId']] = person['id']
        else:
            xlink[person['userName']] = person['id']
    except:
        x = 0

for user in users:
    try:
        uri = "https://www.workplace.com/scim/v1/Users/%s" % xlink[user]
        r = requests.get(uri, headers=headers)
        state = r.json()
        if state['active'] == False:
            state['active'] = True
            r = requests.put(uri, data=json.dumps(state), headers=headers)
            print(r.json())
        else:
            print "User %s was already active" % user
    except ValueError:
        x = 0
