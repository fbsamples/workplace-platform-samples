# Export a Campaign Activity

This PowerShell script allows to export analytics (comments, replies, likes, reactions, seen_by, shares) for all posts in Workplace belonging to a campaign (ie. which use the same hashtags).

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read Group Content", "Read Work Profile" and "Read User Email Address" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Find ids of groups you'd like to monitor. Go in a browser to each Workplace group you would like to include in analytics, take note of the GroupId from the URL you see in the browser bar:
 
   ```powershell
   https://INSTANCE-NAME.workplace.com/groups/GROUP-ID/
   ```
 
## Run

* Run the script by passing the GroupId and `accessToken.js` file as input:

   ```powershell
   ./exportCampaignActivity.ps1 -GroupIds GroupId, GroupId -Hashtags #hashtag1, #hashtag2 -WPAccessToken accessToken.js -StartDate DD-MM-YYYY
   ```

   Here are the details of the passed params:

   | Parameter             | Description                                                       |  Type           |  Required    | 
   |:---------------------:|:-----------------------------------------------------------------:|:---------------:|:------------:|
   | {GroupId}, {GroupId}  |  List of group ids to include in analytics                        | _Array[String]_ | Yes          |
   | {hashtag}, {hashtag}  |  List of hashtags to track a campaign                             | _Array[String]_ | Yes          |
   | WPAccessToken         |  The path for the JSON file with the access token                 | _String_        | Yes          |
   | StartDate             |  The date starting from we need to extract contents, typically is the start date of the campaign (DD-MM-YYYY) | _String_ | Yes          |
   
* A file named `campaign-analytics-[hashtags].xlsx` will be created in the same folder where your run the script. 
   It will include all posts in the campaign and an analysis of relative reactions/engagement.
