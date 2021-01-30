# Bulk update Employee Ids for Workplace Users

This PowerShell script allows to change the Employee ID of Workplace Users in bulk.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Accounts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Export your users' profile data: As an admin, you can export profile data by going to the People Tab in the Admin Portal > Edit People button > Download File button in the dialog window that will open. You will then receive an email message with a link to download a XLSX file containing the exported user data.

 * Edit the`Employee ID` column in the XLSX file and fill it with the new Employee ID of the users you wish to update.

   | Full Name   |      Email    |  ...  |     Employee ID      |
   |:-----------:|:-------------:|:-----:|:--------------------:|
   | Fox A       |  foxA@xyz.com |  ...  |     1234-2132-2314   |
   | Fox B       |  foxB@xyz.com |  ...  |     5242-4213-1341   |
   | Fox C       |  foxC@yyy.com |  ...  |     7553-1314-1315   |

    _Note:_ The script will skip updating a user if the Employee ID field is empty.
    _Note:_ The excel file should contain the User ID column populated with User IDs. If this column is not present the script will fail to retrieve users to update.
    _Note:_ Please be sure the file uses a plain formatting (no tables, etc.).

## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./ChangeBulkEmployeeId.ps1 -WPExportedUsers workplace_users.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedUsers   |  The path for the XLSX file with the exported user data    | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |
