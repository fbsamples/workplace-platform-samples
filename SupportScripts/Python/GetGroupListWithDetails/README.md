# Get and export group list with details
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to get all [groups](https://developers.facebook.com/docs/workplace/reference/graph-api/group) from your Workplace instance and obtain the name, last activity date (date of the last comment or post), description, privacy, number of members and list of admins. Finally it exports them to a CSV file.

## SETUP
Edit the code to add the required parameters and then save the code as `export_groups.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read user email", Read group content", "Manage group content", "Manage groups" and "Read group membership".

## RUN

Run the script in a command line as follows:

```python
python export_groups.py
```

It will print in console the data in dict format and it will also export it to a CSV file called `group_export.csv`.
