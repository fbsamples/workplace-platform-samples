# Delete a list of users in bulk

**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, users whose Workplace internal ID is provided in the CSV will be deleted from Workplace.
Only **unclaimed accounts** can be deleted using this method.

## DESCRIPTION
This usecase example shows how to delete in bulk a list of [users](https://developers.facebook.com/docs/workplace/reference/graph-api/member) passing their Workplace IDs in a list within a CSV file.

## SETUP
Edit the code to add the required parameters (access token) and then save the code as `delete_users.py`. Also modify the CSV file to include the list of Workplace internal IDs to be deleted, and then save the file as `ids_of_users_to_delete.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

If you need a list of the Workplace internal IDs, [you can export it from the People section of the admin panel](https://www.workplace.com/help/work/1858663031075098). The column in the exported file is called "User ID".

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). You will need at least the permission to "Provision user accounts".

## RUN
Run the script in a command line as follows:

```python
python delete_users.py
```

It will delete the unclaimed users in the list from Workplace, and it will print in console the results of these operations.
