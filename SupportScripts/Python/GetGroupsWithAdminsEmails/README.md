# Get Groups with Admin Emails

**Language:** Python v3.7

## DESCRIPTION
This script retrieves information about Workplace groups and their administrators' email addresses, and saves the output to a CSV file.

## SETUP
add environment variables as per the table below, or create a file "accessToken" with nothing but the integration access token in it.  It goes in the same directory as the script.

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in this link. The integration should at least have the following permissions: "Read group content" and "Manage groups".  Others may be needed.  Use minimum-access principles.

### PARAMETERS
| Parameter | Expected ENV var | Description | Type | Required |
| --- | --- | --- | --- | --- |
| accessToken | WP_ACCESS_TOKEN | The access token of the Workplace integration | String | Yes |
| verbose | VERBOSE | Enable verbose mode for additional output | Boolean | No |


## RUN
Run the script in a command line as follows:
```python
export WP_ACCESS_TOKEN=xxxx

python getGroupsWithAdminsEmails.py
```

## OUTPUT
The CSV file will have 4 columns: Group Name, Group ID, an admin's Display Name, and the Email of the admin.
