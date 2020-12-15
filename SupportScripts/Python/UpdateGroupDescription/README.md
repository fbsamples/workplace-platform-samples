# Update description of a list of groups
  
**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. Once the script is run, descriptions provided in the CSV will be updated on Workplace and there is no way to roll them back.

## DESCRIPTION
This usecase example shows how to update in bulk the description of a list of [groups](https://developers.facebook.com/docs/workplace/reference/graph-api/group) providing group ids and descriptions in a CSV file. For example:

numeric_group_id -> this is my new description

## SETUP
Edit the code to add the required parameters (access token) and then save the code as `update_group_description.py`. Also modify the CSV file to include the list of groups to be updated and save the file as `group_description_change.csv`.
Please find the information about the parameters below. There is an example of the CSV file in the folder too.

### PARAMETERS
Here are the details of the script parameters to be replaced in the script:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).

## RUN
Run the script in a command line as follows:

```python
python update_group_description.py
```

It will replace the descriptions of the groups on Workplace, and it will print in console the results of these operations.
