# Retrieve Chat Message Information

This PowerShell script searches the workplace messages sent or received by a specific user for a predefined keyword or sentence and returns the graph-api urls related to that message.<br/>
Returned urls are in the form of: https://graph.facebook.com/{message_id}?user={user_id}<br/>
The returned user_id are the ones of the message sender and message recipients.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).
<br/>This requires at least "Read all messages" permissions.
<br/>Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Retrieve the User Id of the message sender or receiver by heading to the Admin Panel -> People
 <br/>Select the desired user and click on their name to navigate to their profile page
 <br/>From URL of the user profile page, copy the user ID e.g. profile.php?id={USER ID}

## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./RetrieveMessageInfo.ps1 -WPAccessToken accessToken.js -WPUser <User ID> -MessageContent "test message"
   ```

   For example if I sent a message stating "This is a test, please ignore" <br/>
   I can set -MessageContent "This is a test" and the script will retrieve all the messages I sent or received which are including the sentence "This is a test".   </br>
   </br>
   It is also possible to search by date instead by running the script as:

   ```powershell
   ./RetrieveMessageInfo.ps1 -WPAccessToken accessToken.js -WPUser <User ID> -MessageDate <YYYY-MM-DD>
   ```
   This will retrieve all messages sent by a specific user on the specified date. This search method is recommended when searching for pictures/gifs.
   </br>
   </br>
   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | WPUser            |  The Workplace ID of the sender or receiver of the message | _String_ | Yes          |
   | MessageContent    |  A few words contained in the message                      | _String_ | No           |
   | MessageDate       |  Date when the message was sent in format YYYY-MM-DD       | _String_ | No           |

   *Note: Although MessageContent and MessageDate are not required parameters, the search will return no results unless at least one of them is specified.