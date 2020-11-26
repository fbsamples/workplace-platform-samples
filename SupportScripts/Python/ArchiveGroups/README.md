# Archive list of groups
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to archive [groups](https://developers.facebook.com/docs/workplace/reference/graph-api/group) on your Workplace instance providing their IDs in a CSV file.

## SETUP
Edit the code to add the required parameters and then save the code as `archive_groups.py`. Also modify the CSV file to include the list of group IDs to be updated (one ID per line) and save the file as `group_to_archive.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permission: "Manage groups".

## RUN

Run the script in a command line as follows:

```python
python archive_groups.py
```

It will archive the groups on Workplace, and it will print in console the results of these operations.
