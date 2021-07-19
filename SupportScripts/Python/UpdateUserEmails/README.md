# Update a list of user emails

**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, emails provided in the CSV will be modified on Workplace and there is no way to roll it back.

## DESCRIPTION
This usecase example shows how to update in bulk a list of [emails](https://developers.facebook.com/docs/workplace/reference/graph-api/member) providing the old and new emails in a CSV file. For example:

`existing_email@yourdomain.com,new_email@yourdomain.com`

Alternatively, you can also provide the Workplace user ID instead of the email address:

`wp_user_id,new_email@yourdomain.com`

## SETUP
* Make sure that the field Email address is marked as modifiable by the Identity Provider within the [Profile Settings](https://work.workplace.com/work/admin/profile_settings) of the Admin panel.
* Edit the code to add the required parameters (access token) and then save the code as `update_emails.py`.
* Modify the CSV file to include the list of emails/IDs to be updated and save the file as `email_list_change.csv`.

Please find the information about the parameters below. There is an example of the CSV file in the folder too.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).
Please make sure that the integration created on Workplace has at least the "Manage work profiles" permission.

## RUN
Run the script in a command line as follows:

```python
python update_emails.py
```

It will replace the old (existing) emails with the new ones on Workplace, and it will print in console the results of these operations.
