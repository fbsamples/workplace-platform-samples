# Promote group members to group admins
  
**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, user whose ids were provided in the CSV will be promoted to group admins on Workplace and there is no automatic way to roll them back.

## DESCRIPTION
This usecase example shows how to promote [members](https://developers.facebook.com/docs/workplace/reference/graph-api/member) of [groups](https://developers.facebook.com/docs/workplace/reference/graph-api/group) to group admins providing group ids and user_ids in a CSV file. For example:

numeric_group_id -> member_user_id

## SETUP
* Edit the code to add the required parameters (access token) and then save it as `promote_group_member.py`.
* Modify the CSV file to include the list of groups to be updated along with the user IDs that need to be admins, and save the file as `group_admin_change.csv`.
* Please find the information about the parameters below. There is an example of the CSV file in the folder too.

### PARAMETERS
Here are the details of the script parameters to be replaced in the script:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The permissions of the integration need to include at least "Read group membership" and "Manage groups".

## RUN
Run the script in a command line as follows:

```python
python promote_group_member.py
```

It will promote the users (members) in the list to admins of the corresponding groups on Workplace, and it will print in console the results of these operations.
