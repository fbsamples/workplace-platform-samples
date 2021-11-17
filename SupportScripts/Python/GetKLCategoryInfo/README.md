# Get and export the data of a KL category to a file

**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to get and export the content and info of a Knowledge Library [category](https://developers.facebook.com/docs/workplace/reference/graph-api/category) from your Workplace instance. The data that is retrieved and exported for the category is: title, content, status, audience, content, editor, date when it was last updated and the same info of its subcategories.

## SETUP
Edit the code to add the required parameters and then save the code as `export_kl_category.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    |
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |
| category_id      |  The ID of the category from which you want to retrieve the data             | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permission: "Read Knowledge Library content".

## RUN

Run the script in a command line as follows:

```python
python export_kl_category.py
```

It will export the data in JSON format to a TXT file called `category_data.txt`.
