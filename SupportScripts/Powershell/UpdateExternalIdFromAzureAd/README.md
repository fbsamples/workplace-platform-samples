# Auto Update Azure ID in Workplace

This PowerShell script checks your Azure Active Directory for  the user ObjectID and verifies whether the same ID is stored in Workplace(as ExternalId) or if there are discrepancies.
In case of discrepancies it prompts the user to update the ExternalID in Workplace to match the Azure Active Directory ObjectID value.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).
<br/>This requires at least "Manage accounts" permissions.
<br/>Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Note: Depending on the amount of users in your directory, the script may take a while to run. A progress bar is shown to display the progress of the script.
 * Note: This only works for Azure Active Directory
 
## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./update_externalid_from_azuread.ps1 -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |