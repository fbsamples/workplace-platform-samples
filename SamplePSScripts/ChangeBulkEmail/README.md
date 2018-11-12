# Bulk Editing Emails for Workplace users

This PowerShell script allows to change the email address field for Workplace users in bulk.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Accounts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Export your users' profile data: As an admin, you can export profile data by going to the People Tab in the Admin Portal > Edit People button > Download File button in the dialog window that will open. You will then receive an email message with a link to download a XLSX file containing the exported user data.
 
 * Add a `NewEmail` column in the XLSX file and fill it with the new email address for the users you would like to update profile data.
 
   | Full Name   |      Email    |  ...  |     NewEmail      |
   |:-----------:|:-------------:|:-----:|:-----------------:|
   | Fox A       |  foxA@xyz.com |  ...  |  foxie@xyz.com    |
   | Fox B       |  foxB@xyz.com |  ...  |  vulpis@xyz.com   |
   | Fox C       |  foxC@yyy.com |  ...  |  wolfie@zzz.com   |

    _Note:_ The script will skip the email update for a user if the NewEmail field is empty or no Email field is populated (e.g. Email-less accounts).
    
    _Note:_ Please be aware of the column name format. It is `NewEmail` without spaces (e.g. no `New Email`). Please also be sure the file uses a plain formatting (no tables, etc.).

## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./changeBulkEmail.ps1 -WPExportedUsers workplace_users.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedUsers   |  The path for the XLSX file with the exported user data    | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |