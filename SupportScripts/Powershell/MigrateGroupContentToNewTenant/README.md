# Migrate group content

This PowerShell script allows to migrate group content (posts and comments) to a new group, that is automatically created, in a different Workplace tenant/instance.

## Setup

Create two [custom integrations](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating):
* Create a new Custom Integration in the Workplace Admin Panel of the original tenant/instance.<br/>This functionality requires at least "Read Group Content", "Read Group Membership" and "Read User Email" permissions. Take note of the Access Token in the integration as this will be the `ORIGIN-ACCESS-TOKEN`.
* Create a new Custom Integration in the Workplace Admin Panel of the destination tenant/instance.<br/>This functionality requires at least "Read User Email", "Manage Groups", "Create Link Previews" and "Manage Group Content" permissions. Take note of the Access Token in the integration as this will be the `DESTINATION-ACCESS-TOKEN`.
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
 
## Run

* Run the script by passing the OriginGroupId and `accessToken.js` file as input:

   ```powershell
   ./groupContentCloner.ps1 -OriginGroupId {GroupId} -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter            | Description                                                       |  Type    |  Required    | 
   |:--------------------:|:-----------------------------------------------------------------:|:--------:|:------------:|
   | OriginGroupId   |  GroupId retieved from the URL                         | _String_ | Yes          |
   | WPAccessToken        |  The path for the JSON file with the access token                 | _String_ | Yes          |
