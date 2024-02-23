# Bulk Group Archival with Backup Admin

**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to archive multiple groups on your Workplace instance and add a backup admin to each group. The script also sends an archival message to each group. The groups to be targeted are listed in a CSV file, and the script receives this file as input.

## SETUP
Edit the code to add the required parameters and then save the code as `archive_with_message.py`. Information about the parameters below.

### PARAMETERS
| Parameter | Expected ENV var | Description | Type | Required |
| --- | --- | --- | --- | --- |
| accessToken | WP_ACCESS_TOKEN | The access token of the Workplace integration | String | Yes |
| fileName | WP_GROUPS_TO_ARCHIVE_FILENAME | The name of the CSV file that contains the list of groups to target | String | Yes |
| backupAdminEmail | WP_MAINT_ADMIN_EMAIL | The email address of the backup admin to be added to each group.  This must be the email of an existing Workplace user that is a valid admin. | String | Yes |

The CSV file expects 3 columns, and Group Name that can be blank (just for human readability), the Group ID, and an `archivalMessage`.  The message to be sent to each group after archiving it.   The `defaultArchivalMessage` is 'This group is being archived.'

All posts will appear with the name and avatar of the integration from which the access token was generated:

### GENERATE ACCESS TOKEN

More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read group content" and "Manage groups".

## RUN

Run the script in a command line as follows:
```python
export WP_ACCESS_TOKEN=xxxx
export WP_GROUPS_TO_ARCHIVE_FILENAME=yyyyy
export WP_MAINT_ADMIN_EMAIL=zzzzzz

python archive_with_message.py
```
