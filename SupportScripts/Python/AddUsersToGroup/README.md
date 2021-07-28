# Add a list of users to a group in bulk using their emails

**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to add in bulk to a [group](https://developers.facebook.com/docs/workplace/reference/graph-api/group) a list of [users](https://developers.facebook.com/docs/workplace/reference/graph-api/member) using their email addresses.

## SETUP
* Create an integration and generate an access token (more info below).
* Edit the code to add the required parameters: access token and group id.
* Save the code as `add_users_group.py`.
* Modify the CSV file to include the list of emails to be added to the group and save the file as `email_list.csv`.
* Run the script.

Please find the information about the parameters below. There is an example of the CSV file in the folder too.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |
   | group_id      |  The group id of the group in which you want to add them. It can be found in the url of the Workplace group             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).
You will need at least the permissions to "Read user email addresses" and "Manage groups".

## RUN
Run the script in a command line as follows:

```python
python add_users_group.py
```

It will add all the users whose email is in the CSV to the Workplace group that you specified, and it will print in console the results of these operations.
