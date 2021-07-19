# Export a list of users with insights

**Language:** Powershell v. 7.0.3

## DESCRIPTION
This usecase example shows how to export all [users](https://developers.facebook.com/docs/workplace/reference/graph-api/member) that are part of your Workplace instance along with their WP Insights to a XLSX file.
Some of the data you will be able to retrieve per user is:
* Active in the Last 28 Days
* Active in the Last Week
* Active in the Last Day
* Active in the Last 28 Days on Workplace Mobile App
* Active in the Last Week on Workplace Mobile App
* Active in the Last Day on Workplace Mobile App
* Messages in the Last 28 Days
* Messages in the Last Week
* Messages in the Last Day
* Post in the Last 28 Days
* Post in the Last Week
* Post in the Last Day
* Comment in the Last 28 Days
* Comment in the Last Week
* Comment in the Last Day
* Contributor Score in the Last 28 Days
* Contributor Score in the Last Week
* Contributor Score in the Last Day

[Here you have a complete list of fields](https://developers.facebook.com/docs/workplace/reference/graph-api/data-export#employee-data-export--job-type--work-file-export-user-) that are included in the file.


## SETUP

* Create a new Custom Integration in the Workplace Admin Panel: [Create a custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations-new/#creating).<br/>This requires at least "Export employee data" permission. Take note of the Access Token.

* Create a file named `accessToken.js` with the following content:

   ```javascript
   {
         "accessToken" : "YOUR-ACCESS-TOKEN"
   }

## RUN

* Run the script by passing the download path and `accessToken.js` file as input:

   ```powershell
   ./exportUserData.ps1 --UserDataExportFilePath "parthtomyfile/file.xlsx" -WPAccessToken accessToken.js
   ```

* It will download the export file to the specified path. It will also print the url to download it in the console.

### PARAMETERS
Here are the details of the script parameters to be replaced:

 | Parameter             | Description                                                       |  Type           |  Required    |
   |:---------------------:|:-----------------------------------------------------------------:|:---------------:|:------------:|
   | WPAccessToken         |  The path for the JSON file with the access token                 | _String_        | Yes          |
   | UserDataExportFilePath             |  Full path where the data export file should be saved | _String_ | Yes          |
