# Export Post Activity

This PowerShell script allows to export analytics (comments, replies, likes, reactions, seen_by) for a post in Workplace.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read Group Content", "Read Work Profile" and "Read User Email Address" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Find your GroupId and PostId. Navigate to the permalink of the post you would like to extract Analytics for, take note of the GroupId and PostId from the URL you see in the browser bar:
 
   ```powershell
   https://INSTANCE-NAME.workplace.com/groups/GROUP-ID/permalink/POST-ID
   ```
 
## Run

* Run the script by passing the GroupId and `accessToken.js` file as input:

   ```powershell
   ./exportPostActivity.ps1 -PostId {GroupId}_{PostId} -WPAccessToken accessToken.js -StartDate DD-MM-YYYY
   ```

   Here are the details of the passed params:

   | Parameter            | Description                                                       |  Type    |  Required    | 
   |:--------------------:|:-----------------------------------------------------------------:|:--------:|:------------:|
   | {GroupId}_{PostId}   |  Concatenate GroupId and PostId with a _                          | _String_ | Yes          |
   | WPAccessToken        |  The path for the JSON file with the access token                 | _String_ | Yes          |
   | StartDate            |  The date starting from we need to extract contents, typically is the date of the post (DD-MM-YYYY) | _String_ | Yes          |
   
* A file named `stats-[GroupID]_[PostID].xlsx` will be created in the same folder where your run the script. 
   It will include general stats about the post and a list of all the comments/replies and an analysis of relative reactions.
