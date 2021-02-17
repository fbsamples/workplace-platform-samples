# Reactivate a list of user emails/IDs

**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, users whose email/Workplace internal ID is provided in the CSV will have their accounts reactivated on Workplace

## DESCRIPTION
This usecase example shows how to reactivate a target list of accounts detailed in a CSV file. For example:

user1@yourdomain.com
user2@yourdomain.com

## SETUP
Edit the code to add the required parameters (access token) and then save the code as `bulk_reactivate.py`. Also modify the CSV file to include the list of emails/Workplace internal IDs to be reactivated, and save the file as `email_list.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

If you need a list of the Workplace internal IDs, [you can export it from the People section of the admin panel](https://www.workplace.com/help/work/1858663031075098). The column in the exported file is called "User ID".

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). You will need at least the permissions to "Manage Accounts" and "Provision User Accounts".

## RUN
Run the script in a command line as follows:

```python
python bulk_reactivate.py
```

It will update the active status of the users in the list to 'true' on Workplace, and it will print in console the results of these operations.
