# Upload a file to send it in a chat
import requests, json

#Get the access token from a file named accessToken
f = open("accessToken", "r")
TOKEN = f.read()
TOKEN = TOKEN.rstrip("\r\n")
f.close()

#Generate the Authentication header
api = "https://graph.workplace.com/me/message_attachments"
url = "{}?access_token={}".format(api, TOKEN)

localRouteToImage = 'local/route/to/image.png'
meta = {"message": '{"attachment":{"type":"image","payload":{"is_reusable":true}}}'}
f = {"filedata": ('test.png', open(localRouteToImage, 'rb'), 'image/png')}

# Post
r = requests.post(url, meta, files=f)
print(r.json())
