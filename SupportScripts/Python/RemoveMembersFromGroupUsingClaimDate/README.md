# Remove members from group based on when they claimed their accounts
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to remove [members](https://developers.facebook.com/docs/workplace/reference/graph-api/member) whose claim date is older than a given date from a [group](https://developers.facebook.com/docs/workplace/reference/graph-api/group) on your Workplace instance.


## SETUP
Edit the code to add the required parameters and then save the code as `remove_members_from_group_claim_date.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | accessToken      |  The access token of the Workplace integration             | _String_ | Yes |
   | groupId      |  The groupId is the ID of a group from which you want to remove the inactive members           | _String_ | Yes |
   | lastClaimDate      |  The lastClaimDate is the date used to compare the claim date of the group members to remove them         | _Date (Y-m-d)_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read user email addresses", "Read group membership", "Manage groups" and "Read work profile".

## RUN

Run the script in a command line as follows:

```python
python remove_members_from_group_claim_date.py
```

It will print in console the confirmation when each user has been removed.
