# Create a list of groups with group parameters

**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, groups provided in the CSV will be created on Workplace

## DESCRIPTION
This usecase example shows how to create a target list of groups detailed in a CSV file. For example:

   | group Name   | Group Description                |  Privacy Settings |  Post_Permissions | Join_Setting |
   |:------------:|:--------------------------------:|:-----------------:|:-----------------:|:------------:|
   | Group 1      | This is group 1 for API sample.  | CLOSED            | NONE              | ADMIN_ONLY   |

Options
 - Privacy Settings: [CLOSED, OPEN, SECRET]
 - Post_Permissions: [NONE, ADMIN_ONLY]
 - Join_Setting: [NONE, ANYONE, ADMIN_ONLY]

 More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/reference/graph-api/group).

## SETUP
Edit the code to add the required parameters (access token) and then save the code as `bulk_groupcreation.py`. Also modify the CSV file to include the list of emails/Workplace internal IDs to be reactivated, and save the file as `group_list.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

If you need a list of the Workplace internal IDs, [you can export it from the People section of the admin panel](https://www.workplace.com/help/work/1858663031075098). The column in the exported file is called "User ID".

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_        | Yes          |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). You will need at least the permissions to "Manage groups".

## RUN
Run the script in a command line as follows:

```python
python bulk_groupcreation.py
```

It will add the groups which are in CSV to Workplace with Group Privacy, Post Permission and Join Settings, and it will print in console the group IDs created. You can add group members using [AddUsersToGroup](https://github.com/fbsamples/workplace-platform-samples/tree/main/SupportScripts/Python/AddUsersToGroup)
