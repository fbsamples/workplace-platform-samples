# Get feed data from a list of groups with details
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to get all [posts](https://developers.facebook.com/docs/workplace/reference/graph-api/post) from a given list of [groups](https://developers.facebook.com/docs/workplace/reference/graph-api/group) and obtain all their details. Finally it exports them to a CSV file.

## SETUP
Edit the code to add the required parameters (ids of groups, access token and start date) and then save the code as `group_posts_detail.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | group_ids         |  The IDs of the groups                                     | _Array[String]_ | Yes          |
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |
   | since_date        |  The starting date from which we need to extract content (DD-MM-YYYY)            | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/).

## RUN

Run the script in a command line as follows:

```python
python group_posts_detail.py
```

It will print in console the data in dict format and it also exports it to a CSV file called `post_export.csv`.
