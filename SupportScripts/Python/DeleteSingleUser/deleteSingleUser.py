# Use Graph API to delete a user with the email of a given user
import requests, json

#Get the access token from a file named accessToken
f = open("accessToken", "r")
TOKEN = f.read()
TOKEN = TOKEN.rstrip("\r\n")
f.close()

#Generate the content header
headers = {'Content-Type': 'application/json'}

#Get User URI
userEmail = "user1@domain.com"
getUser = "https://graph.workplace.com/%s?access_token=%s" % (userEmail, TOKEN)
r = requests.get(getUser, headers=headers)
response=r.json()
id = response['id']

deleteUser = "https://graph.workplace.com/%s?access_token=%s" % (id, TOKEN)
r = requests.delete(deleteUser, headers=headers)
response = r.json()
print(response)
