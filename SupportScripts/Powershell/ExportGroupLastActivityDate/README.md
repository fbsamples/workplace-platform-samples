# Export Group Last Activity Date

This PowerShell script allows to export last activity date for groups (e.g. the last time a group was updated or a new post was created) in Workplace.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read Group Content", "Read Work Profile" and "Read User Email Address" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
## Run

* Run the script by passing the GroupId and `accessToken.js` file as input:

   ```powershell
   ./ExportGroupLastActivityDate.ps1 -WPAccessToken accessToken.js -Interactive
   ```

   Here are the details of the passed params:

   | Parameter            | Description                                                       |  Type    |  Required    | 
   |:--------------------:|:-----------------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken        |  The path for the JSON file with the access token                 | _String_ | Yes          |
   | Interactive          |  If the script should prompt for a user OK for each entry         | _Switch_ | No           |
   
* A file named `last-activity-stats.xlsx` will be created in the same folder where your run the script. 
   It will include last activity information about the groups in your Workplace instance
