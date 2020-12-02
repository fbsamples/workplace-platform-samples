# Migrate group members to people sets

This PowerShell script allows to migrate group content (posts and comments) to a new group, that is automatically created.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read Group Content", "Manage Groups", "Create Link Previews" and "Manage Group Content" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "ORIGIN-ACCESS-TOKEN",
	        "destAccessToken" : "DESTINATION-ACCESS-TOKEN"
   }
   ``` 
 
 * Find your GroupId. Navigate to the permalink of the group to migrate, take note of the GroupId in the browser bar:
 
   ```powershell
   https://INSTANCE-NAME.workplace.com/groups/GROUP-ID/
   ```
   
 * Export the users in the destination instance in a xlsx file from the Workplace Admin Panel, People section and rename the file to:
 
     ```
     users-sheet-workplace.xlsx
     ```

 
## Run

* Run the script by passing the OriginGroupId and `accessToken.js` file as input:

   ```powershell
   ./groupMembersToPeopleSets.ps1 -OriginGroupId {GroupId} -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter            | Description                                                       |  Type    |  Required    | 
   |:--------------------:|:-----------------------------------------------------------------:|:--------:|:------------:|
   | OriginGroupId   |  GroupId retieved from the URL                         | _String_ | Yes          |
   | WPAccessToken        |  The path for the JSON file with the access token                 | _String_ | Yes          |
