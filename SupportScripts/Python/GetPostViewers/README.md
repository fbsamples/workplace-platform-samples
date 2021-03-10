# Get and export the list of users who saw a post
  
**Language:** Python v3.7

## DESCRIPTION
This usecase example shows how to get all [users](https://developers.facebook.com/docs/workplace/reference/graph-api/member) who saw* a speficic [post](https://developers.facebook.com/docs/workplace/reference/graph-api/post) on your Workplace instance. The user list contains the ID, Name, Email, Department, Division, Organization and Title of each user. Finally, it exports this data to a CSV file.

* On Workplace, a post is considered as seen if the user spent at least a fraction of second in that post.

## SETUP
Edit the code to add the required parameters and then save the code as `get_post_viewers.py`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |
   | grouppost_id      |  The grouppost_id is a concatenation of the group ID and the post ID. Format: groupid_postid            | _String_ | Yes |

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration should at least have the following permissions: "Read group content", "Read user email addresses" and "Read work profile".

## RUN

Run the script in a command line as follows:

```python
python get_post_viewers.py
```

It will print in console the data in dict format and it will also export it to a CSV file called `user_who_saw_the_post.csv`.
