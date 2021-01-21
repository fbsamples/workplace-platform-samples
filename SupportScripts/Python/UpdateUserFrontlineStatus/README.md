# Update frontline status for a list of user emails/IDs
  
**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, users whose email/Workplace internal ID is provided in the CSV will have their [frontline status](https://www.workplace.com/help/work/1145121065660748) modified on Workplace.

## DESCRIPTION
This usecase example shows how to update in bulk the frontline status of a list of [emails or Workplace IDs](https://developers.facebook.com/docs/workplace/reference/graph-api/member) and the target frontline status in a CSV file. For example:

existing_email@yourdomain.com -> true
123456789 -> false

## SETUP
Edit the code to add the required parameters (access token) and then save the code as `update_frontline.py`. Also modify the CSV file to include the list of emails/Workplace internal IDs to be updated with their target frontline status (true or false), and save the file as `email_list_change.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

If you need a list of the Workplace internal IDs, [you can export it from the People section of the admin panel](https://www.workplace.com/help/work/1858663031075098). The column in the exported file is called "User ID".

`has_access` is an *Enterprise* only feature and its use is documented in [developer docs](https://developers.facebook.com/docs/workplace/account-management/graph). By default its set to True and is not required for most use cases. 

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). You will need at least the permissions to "Read work profile", "Manage work profiles" and "Manage Frontline Access".

## RUN
Run the script in a command line as follows:

```python
python update_frontline.py
```

It will update the frontline status of the users in the list on Workplace, and it will print in console the results of these operations.
