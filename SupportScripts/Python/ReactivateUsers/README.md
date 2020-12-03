# Reactivate users with their usernames
  
**Language:** Python

## DISCLAIMER
Use at your own risk. Once the script is run, users whose usernames are provided in the CSV file will be reactivated on Workplace.

## DESCRIPTION
This usecase example shows how to reactivate in bulk a list of users from Workplace providing their [usernames](https://developers.facebook.com/docs/workplace/reference/account-management-api#coreschema) in a CSV file. 

## SETUP
* Save the code as `bulkActivate.py`.
* Modify the CSV file to include the list of usernames to be reactivated and save the file as `userNames.csv`.
* Modify the accessToken file to include the Access Token of your custom integration.

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).

## RUN
Run the script in a command line as follows:

```python
python bulkActivate.py
```