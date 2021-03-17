# Anonymise user profile data on Workplace using their Workplace ID

**Language:** Powershell 7

## Disclaimer
Use at your own risk. Once the script is run, the profile data of the user whose Workplace internal ID is provided will be overwritten with new values and the script doesn't have a mechanism to undo the changes.

## Description
This PowerShell script allows to anonymise the user profile data of a user on Workplace by passing their ID.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage accounts" permission. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
 * Find the UserId of the user to anonymise. Navigate to the permalink of the user, and take note of the UserId in the browser bar:
 
   ```powershell
   https://INSTANCE-NAME.workplace.com/profile.php?id=USER-ID
   ```
 
## Run

* Run the script by passing the UserId and `accessToken.js` file as input:

   ```powershell
   ./anonymiseUserFromId.ps1 -UserId {UserId} -WPAccessToken accessToken.js
   ```

## Parameters
Here you have the the details of the parameters to be used:

   | Parameter            | Description                                                       |  Type    |  Required    | 
   |:--------------------:|:-----------------------------------------------------------------:|:--------:|:------------:|
   | UserId   |  User Id retieved from the user profile URL                         | _int_ | Yes          |
   | WPAccessToken        |  The path for the JSON file with the access token                 | _String_ | Yes          |
