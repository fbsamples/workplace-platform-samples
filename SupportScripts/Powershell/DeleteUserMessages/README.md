# Delete Chat Messages for a user

This PowerShell script searches the workplace messages sent by a user A and received by a user B, and delete them.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).
<br/>This requires at least "Read all messages" and "Delete chat messages" permissions.
<br/>Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```

 * Retrieve the User Id of the messages sender and receiver by heading to the Admin Panel -> People
 <br/>Select the desired user and click on their name to navigate to their profile page
 <br/>From URL of the user profile page, copy the user ID e.g. profile.php?id={USER ID}

## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./DeleteUserMessages.ps1 -WPAccessToken accessToken.js -WPSenderUser <Sender User ID> -WPReceiverUser <Receiver User ID>
   ```
   </br>
* When you run the script and confirm that you want to go ahead with the deletion, all messages sent from the sender to the receiver will be deleted for the receiver, no matter if they happened in a 1to1 chat conversation or in a group.

## Parameters
Here are the details of the params that need to be passed:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | WPSenderUser      |  The Workplace ID of the sender of the message             | _String_ | Yes          |
   | WPReceiverUser    |  The Workplace ID of the receiver of the message           | _String_ | Yes          |
