# Remove members from a group

This PowerShell script allows to remove users from a Workplace group:
* By filtering per email domain in their usernames (Beta)
* By using an XLSX file with the list of users to remove (Beta)

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Groups" and nd "Read User Emails" permissions. Take note of the Access Token.

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

### Test Mode (remove users with a specific email domain from the group)

* Run the script by passing the GroupId, EmailDomain and WPAccessToken as input:

   ```powershell
   ./cleanGroupMembers.ps1 -GroupId GROUP-ID -EmailDomain EMAIL-DOMAIN -WPAccessToken ./accesstoken.js
   ```
   
* The script will list all the users with the specified domain and a summary.

### Test Mode (remove users listed in a XLSX file in input)

* Make sure the XLSX file in input has an header row (no table formatting) with at least an Email or ID column. List all the users you would like to remove from the group there.

* Run the script by passing the GroupId, WPGroupMembers and WPAccessToken as input:

   ```powershell
   ./cleanGroupMembers.ps1 -GroupId GROUP-ID -WPGroupMembers PATH-USERS-TO-REMOVE-XLSX -WPAccessToken ./accesstoken.js
   ```
   
* The script will list all the users with the specified domain and a summary.

### Live Mode (remove users with a specific email domain from the group)

* Run the script by passing the GroupId, EmailDomain, WPAccessToken and Mode as input:

   ```powershell
   ./cleanGroupMembers.ps1 -GroupId GROUP-ID -EmailDomain EMAIL-DOMAIN -WPAccessToken ./accesstoken.js -Mode Live
   ```
   
* The script will stop for each user with the specified email domain in their username and ask the user for an action: Remove from group or Skip it.

### Live Mode (remove users listed in a XLSX file in input)

* Make sure the XLSX file in input has an header row (no table formatting) with at least an Email or ID column. List all the users you would like to remove from the group there.

* Run the script by passing the GroupId, WPGroupMembers, WPAccessToken and Mode as input:

   ```powershell
   ./cleanGroupMembers.ps1 -GroupId GROUP-ID -WPGroupMembers PATH-USERS-TO-REMOVE-XLSX -WPAccessToken ./accesstoken.js -Mode Live
   ```
   
* The script will stop for each user with the specified email domain in their username and ask the user for an action: Remove from group or Skip it.

### Parameters

Here are the details of the script parameters:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | GroupId           |  The ID of the group                                       | _String_ | Yes          |
   | EmailDomain       |  The email domain to filter your user (e.g. 'abc.com')     | _String_ | Yes, one between EmailDomain or WPGroupMembers |
   | WPGroupMembers    |  Path to the XLSX file with the users to remove            | _String_ | Yes, one between EmailDomain or WPGroupMembers |
   | WPAccessToken     |  Path to the JSON file with the access token               | _String_ | Yes          |
   | Mode              |  Set to 'Live' to apply changes. Defaults to 'Test'        | _String_ | No           |