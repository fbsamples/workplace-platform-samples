# Backup User Group Membership

This PowerShell script creates a CSV file with a list of all the groups each member of a file belongs to.
This can be used to track group memberships,run statistics or just to keep a backup of this information.
<br/>It will check every user in the spreadsheet file that you pass and save the following information:
<br/>1- User ID
<br/>2- Group Name
<br/>3- Group Privacy (OPEN/CLOSED/SECRET)
<br/>4- Group ID

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read group membership", "Read user email addresses" and "Read work profile" permissions.<br/>Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Note: Depending on the amount of users and groups the script may take a while to run.
 The output will be in  the form of a .csv file

## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./backupGroupMembershipFromUserList.ps1 -WPAccessToken accessToken.js -WPUserIDFile UserIDs.xlsx
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | WPUserIDFile     |  The path for the XLSX file with the list of IDs/emails of users to backup          | _String_ | Yes          |
