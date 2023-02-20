# Bulk update Authentication Method for Workplace users

This PowerShell script allows to change the Authentication Method of Workplace users in bulk.
This is particularly useful for situations in which users are getting added to an Active Directory after beed using a Workplace password to access the platform.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Accounts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Export your users' profile data: As an admin, you can export profile data by going to the People Tab in the Admin Portal > Edit People button > Download File button in the dialog window that will open. You will then receive an email message with a link to download a XLSX file containing the exported user data.

 * Add a `NewAuthMethod` column in the XLSX file and fill it with the new Authentication Method (i.e. password or sso) of the users you wish to update. More info about the accepted values [in this link](https://developers.facebook.com/docs/workplace/reference/account-management-api/scim-v2#authmethodschema).

   | Full Name   |      Email    |  ...  |     NewAuthMethod   |
   |:-----------:|:-------------:|:-----:|:-------------------:|
   | Fox A       |  foxA@xyz.com |  ...  |   password          |
   | Fox B       |  foxB@xyz.com |  ...  |   sso               |
   | Fox C       |  foxC@yyy.com |  ...  |   password          |

    _Note:_ The script will skip updating a user if the NewAuthMethod field is empty or no Email field is populated (e.g. Email-less accounts).

    _Note:_ Please be aware of the column name format. It is `NewAuthMethod` without spaces (e.g. no `New Auth Method`). Please also be sure the file uses a plain formatting (no tables, etc.).

## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./ChangeBulkAuthMethod.ps1 -WPExportedUsers workplace_users.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedUsers   |  The path for the XLSX file with the exported user data    | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |
