# Export a list of users with insights
  
**Language:** Python v3.7

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
Edit the code to add the required parameters and then save the code as `export_user_data.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permission: "Export employee data".

## RUN

Run the script in a command line as follows:

```python
python export_user_data.py
```

It will download the export file to the root folder with the name `export_user_data_file.xlsx`. Alternatively it will print the url to download it in console.
