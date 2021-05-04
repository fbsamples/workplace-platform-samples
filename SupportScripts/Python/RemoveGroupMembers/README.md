# Remove members from group
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to remove [users](https://developers.facebook.com/docs/workplace/reference/graph-api/member) from a [group](https://developers.facebook.com/docs/workplace/reference/graph-api/group) to which they belong on your Workplace instance.
The script receives a CSV file with a member email per row as an input, and remove those users from the defined group.

## SETUP
Edit the code to add the required parameters and then save the code as `remove_members_from_group.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | accessToken      |  The access token of the Workplace integration             | _String_ | Yes |
   | groupId      |  The groupId is the ID of a group from which you want to remove the members           | _String_ | Yes |
   | fileName      |  The fileName is the name of the CSV file that contains the list of emails from the members that you want to remove            | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read user email addresses" and "Manage groups".

## RUN

Run the script in a command line as follows:

```python
python remove_members_from_group.py
```

It will print in console the confirmation when each user has been removed.
