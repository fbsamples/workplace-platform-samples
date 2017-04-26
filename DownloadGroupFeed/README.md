# Archiving Content to CSV

**Language:** Python v2.7

This script illustrates the basics of downloading bulk data from group posts and flattening to CSV files for auditing or backup purposes.

It shows how to traverse the groups list and filter based on content posted after a timestamp, how to recurse through pages of API results using [cursor-based paging](/docs/graph-api/using-graph-api#paging) and how to use [Field Expansion](/docs/graph-api/using-graph-api#fieldexpansion) on the feed to fetch nested [Comment](/docs/graph-api/reference/object/comments) and [Like](/docs/graph-api/reference/object/likes) counts for each [Post](/docs/workplace/custom-integrations/reference#post) object in a [Group](/docs/workplace/custom-integrations/reference#group) feed.

To run this script, save the code as `download.py`, replace the `YOURTOKEN` and `YOURCOMMUNITYID` fields at the top of the script, and set an appropriate value for the number of days back you want to look, then run the script in a command line as follows:

python download.py

A series of CSV files will be written to the folder in which you execute the script, named after the group name, group ID and timestamp. You may want to run this script on a daily scheduled job, by setting the DAYS variable to 1.
