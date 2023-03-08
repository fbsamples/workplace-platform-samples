# Bulk Editing Locale/Preferred Language for unclaimed Workplace users

This PowerShell script allows to change the locale and preferred language fields for Workplace users (that haven't claimed their account yet) in bulk. If a user has already claimed their account these updates won't be reflected in their profile.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Accounts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Export your users' profile data: As an admin, you can export profile data by going to the People Tab in the Admin Portal > ... > Export Employee information.
 
 * Add a `NewLocale` column in the XLSX file and fill it with the new email address for the users you would like to update profile data.
 
   | Full Name |  User ID  |    Status     |  ...  |  NewLocale |
   |:---------:|:---------:|:-------------:|:-----:|:----------:|
   | Fox A     |  1000000  |  Claimed      |  ...  |    es_ES   |
   | Fox B     |  1000001  |  Invited      |  ...  |    fr_FR   |
   | Fox C     |  1000002  |  Deactivated  |  ...  |    en_US   |

    _Note:_ The script will skip the email update for a user if the NewLocale field is empty or if __User ID__ or __Status__ fields are not populated.
    
    _Note:_ Please be aware of the column name format. It is `NewLocale` without spaces (e.g. no `New Locale`). Please also be sure the file uses a plain formatting (no tables, etc.).

## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./changeBulkLocale.ps1 -WPExportedUsers workplace_users.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedUsers   |  The path for the XLSX file with the exported user data    | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |