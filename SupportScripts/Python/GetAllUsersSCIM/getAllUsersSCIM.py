#Get all users in a Workplace instance via SCIM API

#we are expecting the Access Token to be in a file named accessToken
import requests, json, ast

#Get the access token from a file named accessToken
f = open("accessToken", "r")
TOKEN = f.read()
TOKEN = TOKEN.rstrip("\r\n")
f.close()

#Generate the content header
headers = {'Content-Type': 'application/json'}

getUsers = "https://www.workplace.com/scim/v1/Users?access_token=%s" % TOKEN
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
        getUsers = "https://www.workplace.com/scim/v1/Users?count=%s&startIndex=%s&access_token=%s" % (itemsPerPage, startIndex, TOKEN)
        r = requests.get(getUsers, headers=headers)
        answer = r.json()
        try:
            people = people + answer['Resources']
        except:
            x = 0
except:
    x = 0

for person in people:
    print person
