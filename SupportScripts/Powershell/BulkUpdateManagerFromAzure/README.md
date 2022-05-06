# Bulk Update Manager Attribute from Azure

This PowerShell script is provided as a workaround to mitigate an issue with Workplace Import/One-Click user provisioning with Azure.
At times Workplace Import does not fetch the manager attribute from Azure and this results in organizational units not correctly being defined.
This script will fetch from Azure AD the manager attribute for Workplace users and perform a bulk update via SCIM API.

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

  * Export your users' profile data: As an admin, you can export profile data by going to the People Tab in the Admin Portal > Edit People button > Download File button in the dialog window that will open. You will then receive an email message with a link to download a XLSX file containing the exported user data.

 * Note: Depending on the amount of users in your community, the script may take a while to finish running.
 * Note: This only works for Azure Active Directory and needs to run on a Windows computer. It does not support Powershell on Mac.

## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./bulk_update_manager_from_azure.ps1 -WPExportedUsers workplace_users.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedUsers   |  The path for the XLSX file with the exported user data    | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each entry  | _Switch_ | No           |
