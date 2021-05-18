# Download Group Feed

This PowerShell script allows to export all posts (creator, date, message, attachments) made in a certain Workplace group and provide some high level engagement stats (replies, comments, likes, reactions) for each of them.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read Group Content", "Read Work Profile" and "Read User Email Address" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Find id of the group you'd like to extract the posts from. Navigate in a browser to the Workplace group you would like to export the feed from, take note of the GroupId from the URL you see in the browser bar:

   ```powershell
   https://INSTANCE-NAME.workplace.com/groups/GROUP-ID/
   ```

## Run

* Run the script by passing the GroupId and `accessToken.js` file as input:

   ```powershell
   ./DownloadGroupFeed.ps1 -WPGroupId GroupId -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter             | Description                                                       |  Type           |  Required    |
   |:---------------------:|:-----------------------------------------------------------------:|:---------------:|:------------:|
   | WPGroupId             |  Id of the group from which extract posts                         | _String_        | Yes          |
   | WPAccessToken         |  The path for the JSON file with the access token                 | _String_        | Yes          |
   | Interactive           |  If the script should output logs on screen                       | _Switch_        | No           |
   | StartDate             |  Specify this date to export posts that were updated (or created) only after it. Format: DD-MM-YYYY, will default to all posts in a group (no date) | _String_ | No          |

* A file named `feed-[WPGroupId].xlsx` will be created in the same folder where your run the script.
   It will include all posts from the group and relative replies, reactions and engagement stats.
