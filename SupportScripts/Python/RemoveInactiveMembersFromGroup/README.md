# Remove inactive members from group
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to remove the inactive [members](https://developers.facebook.com/docs/workplace/reference/graph-api/member) ([with accounts not claimed or deactivated](https://www.workplace.com/resources/tech/account-lifecycle/intro)) from a [group](https://developers.facebook.com/docs/workplace/reference/graph-api/group) on your Workplace instance.

We consider a member inactive if they are not group admins, and if they haven't claimed their account or they have been deactivated.

## SETUP
Edit the code to add the required parameters and then save the code as `remove_inactive_members_from_group.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | accessToken      |  The access token of the Workplace integration             | _String_ | Yes |
   | groupId      |  The groupId is the ID of a group from which you want to remove the inactive members           | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read user email addresses", "Read group membership", "Manage groups" and "Read work profile".

## RUN

Run the script in a command line as follows:

```python
python remove_inactive_members_from_group.py
```

It will print in console the confirmation when each user has been removed.
