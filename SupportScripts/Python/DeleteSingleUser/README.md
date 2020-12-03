# Delete a single user by email
  
**Language:** Python

## DISCLAIMER
Use at your own risk. Once the script is run, the user whose email is provided will be deleted from the Workplace instance and there is no way to roll it back.

## DESCRIPTION
This usecase example shows how to delete a Workplace [user](https://developers.facebook.com/docs/workplace/reference/graph-api/member) providing their email address.
There is an additional script to do the same action but using the [SCIM API](https://developers.facebook.com/docs/workplace/reference/account-management-api).

## SETUP
* Save the code as `deleteSingleUser.py` or `deleteSingleUserSCIM.py`.
* Edit the userEmail variable to include the email of the user to be deleted.
* Modify the accessToken file to include the Access Token of your custom integration.

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).

## RUN
Run the scripts in a command line as follows:

```python
python deleteSingleUser.py
```

or

```python
python deleteSingleUserSCIM.py
```