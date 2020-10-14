# Archive Workplace groups in bulk with a XSLX file in input

This PowerShell script allows to archive Workplace groups in bulk.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Groups" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Export the list of groups you'd like to archive: As an admin, you can export groups details by going to the Groups Tab in the Admin Panel > ... > Export group information.  
 * Keep just the groups you'd like to archive in the file, removing those that you wish to keep active.
 * Alternatively, if going through the Groups Export is an expensive task, the script also accepts an `.xlsx` file with at least one column named `Group ID`, containing the Group IDs of groups that you wish to archive. 
    
 _Note:_ It is not possible to archive multi-company groups.
 
## Run

* Run the script by passing the XLSX file and `accessToken.js` file as input:

   ```powershell
   ./archiveGroupsInBulk.ps1 -WPExportedGroupIDs workplace_groups.xlsx -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter          | Description                                                 |  Type    |  Required    | 
   |:------------------:|:-----------------------------------------------------------:|:--------:|:------------:|
   | WPExportedGroupIDs |  The path for the XLSX file with the exported groups data   | _String_ | Yes          |
   | WPAccessToken      |  The path for the JSON file with the access token           | _String_ | Yes          |
   | Interactive        |  If the script should display a message for each operation  | _Switch_ | No           |