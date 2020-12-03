# Use Graph API to delete a user with the email of a given user via SCIM API

import requests, json

#Get the access token from a file named accessToken
f = open("accessToken", "r")
TOKEN = f.read()
TOKEN = TOKEN.rstrip("\r\n")
f.close()

#Generate the content header
AUTH = "Bearer %s" % TOKEN
headers = {'Authorization': AUTH, 'Content-Type': 'application/json'}

#Get User URI
userEmail = "user1@domain.com"
getUser = "https://www.workplace.com/scim/v1/Users?filter=userName%20eq%20%22" + userEmail + "%22"
r = requests.get(getUser, headers=headers)
response = r.json()
User = response['Resources'][0]
id = User['id']

deleteUser = "https://www.workplace.com/scim/v1/Users/%s" % id
r = requests.delete(deleteUser, headers=headers)
print(r.status_code)
