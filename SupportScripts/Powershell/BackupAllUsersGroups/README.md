# Backup User Group Membership

This PowerShell script allows to backup user group membership of your community.
<br/>It will check every user in your community and save the following information:
<br/>1- User ID
<br/>2- Group Name
<br/>3- Group Privacy (OPEN/CLOSED/SECRET)
<br/>4- Group ID

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read group membership" and "Read work profiles" permissions.<br/>Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Note: Depending on the amount of users and groups the script may take a while to run. A progress bar is shown once the total number of users has been identified by the script.
 The output will be in  the form of a .csv file
 
## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./backup_all_users_groups.ps1 -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |