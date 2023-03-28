# Bulk Delete Workplace Posts within a specified date range

This PowerShell script allows to bulk delete Workplace posts within a specified date range.
It will target all users within the community and delete all the user's posts made between the start date and the end date (both start and end dates are included in the deletion range).

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Read work profile",  "Read group content" , "Read user timeline", "Manage user timeline", "Manage group content" and "Manage important posts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ```


## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./DeletePostsDateRange.ps1 -WPAccessToken accessToken.js -StartDate YYYY-MM-DD -EndDate YYYY-MM-DD -Interactive
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |
   | StartDate         |  The start of the date range to scan in format YYYY-MM-DD  | _String_ | Yes          |
   | EndDate           |  The end of the date range to scan in format YYYY-MM-DD    | _String_ | Yes          |
   | Interactive       |  If the script should prompt for a user OK for each change | _Switch_ | No           |
