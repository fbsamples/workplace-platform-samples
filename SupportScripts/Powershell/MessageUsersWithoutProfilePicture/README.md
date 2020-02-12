# Bulk Editing Emails for Workplace users

This PowerShell script allows to bulk message users without a custom profile picture in your community.
The script will just send one message per user and will affect only those users whose profile picture is set to the default silhouette.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Message any member" and "Read work profiles" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Note: The script will send the message "This is an automated message - Please update your profile picture from the default one."
 Feel free to edit this message in the script should you wish to send a different message to the users with a stock profile picture. In order to do this you will need to modify the content of the variable $message_to_send.
 

## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./message_users_without_picture.ps1 -WPAccessToken accessToken.js
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |