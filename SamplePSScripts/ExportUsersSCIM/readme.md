# Export Workplace users via SCIM API

This PowerShell script allows to export the users of a Workplace instance by using SCIM API.

## Setup

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Manage Accounts" permissions. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }
   ``` 
 
## Run

* Run the script by passing the `accessToken.js` file as input:

   ```powershell
   ./exportUsersSCIM.ps1 -WPAccessToken accessToken.js -ParallelGrade 8
   ```

   Here are the details of the passed params:

   | Parameter         | Description                                                |  Type    |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:--------:|:------------:|
   | WPAccessToken     |  The path for the JSON file with the access token          | _String_ | Yes          |   
   | ParallelGrade     |  The # of threads on which the export process will span    | _Int_    | No           |
  
   
* A file named `workplace_employees_info_[yyyy-mm-dd-HH_mm].xlsx` will be created in the same folder where your run the script.
It will populate some columns with values from the SCIM API calls:

   | Fields                 | 
   |:----------------------:|
   | `Full Name`            | 
   | `Email`                | 
   | `User Id`              |
   | `Job Title`            |
   | `Department`           |
   | `Division`             |
   | `Status`               |
   | `Claimed`              |
   | `Claimed Date`         |
   | `Invited`              |
   | `Invited Date`         |
   | `Manager Employee ID`  |
   | `Manager Full Name`    | 