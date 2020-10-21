# Get message data from a particular user/bot
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to get all chat messages sent by a given [member](https://developers.facebook.com/docs/workplace/reference/graph-api/member). Finally it exports them to a TXT file.

## SETUP
Edit the code to add the required parameters (id of member (user or bot ID) and access token) and then save the code as `messages_member.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | member_id         |  The ID of a Workplace member (It can be a user or bot)                                     | _Array[String]_ | Yes          |
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).

## RUN

Run the script in a command line as follows:

```python
python messages_member.py
```

It will print in console the data in dict format and it also exports it to a TXT file called `message_export.txt`.
