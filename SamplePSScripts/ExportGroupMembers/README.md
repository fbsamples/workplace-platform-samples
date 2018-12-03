# Export members from a group

This PowerShell script allows to export the members of a Workplace group to a XLSX file.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Groups" and "Read User Emails" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Find your GroupId. Go in a browser to the Workplace group you would like to extract members from and take note of the GroupId from the URL you see in the browser bar:
 
   ```powershell
   https://INSTANCE-NAME.facebook.com/groups/GROUP-ID
   ```
 
## Run

* Run the script by passing the GroupId and `accessToken.js` file as input:

   ```powershell
   ./exportGroupMembers.ps1 -GroupId THIS-IS-A-GROUP-ID -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | GroupId           |  The ID of the group                                       | _String_ | Yes          |
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   
* A file named `members-[GroupId].xlsx` will be created in the same folder where your run the script. 
   It will have `Name`, `Id`, `Email`, `Administator`, `Location`, `Department` columns.