# Copyright 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import json
import csv
import datetime
import re

# Modify these to suit your needs
TOKEN = "YOURTOKEN"
DAYS = 14

# No need to modify these
GRAPH_URL_PREFIX = "https://graph.workplace.com/"
GROUPS_SUFFIX = "/groups"

# Default paging limit for Graph API# No need to modify, unless you're seeing timeouts
DEFAULT_LIMIT = "100"

# Set to true if you like seeing console output
VERBOSE = True
groups = []

# Calculating a timestamp from DAYS
SINCE = datetime.datetime.now() - datetime.timedelta(days=DAYS)
def getFeed(group, name):

    # Token-based auth header
    headers = {'Authorization': 'Bearer ' + TOKEN, "User-Agent": "GithubRep-DownloadGroupFeed"}

    # Get the relevant group post content for each feed item
    # Include a fetch for like and comment summaries to get total count
    # No need to fetch actual likes &amp; comments, so set the limit to 0
    params = "?fields=permalink_url,from,story,type,message,link,created_time,updated_time,reactions.limit(0).summary(total_count),comments.limit(0).summary(total_count)"

    # Default paging limit
    params += "&amp;limit=" + DEFAULT_LIMIT

    # Time-based limit
    params += "&amp;since=" + SINCE.strftime("%s")

    graph_url = GRAPH_URL_PREFIX + group + "/feed" + params

    result = requests.get(graph_url, headers=headers)
    result_json = json.loads(result.text, result.encoding)

    feed = []

    # Got an error? Ok let's break out
    if "error" in result_json:
        print "Error", result_json["error"]["message"]
        return []

    # Did we get back data?
    if "data" in result_json:
        for feed_item in result_json["data"]:

            # Convenience: Add empty field for message / link if not existent
            feed_item["message"] = feed_item["message"] if "message" in feed_item else ""
            feed_item["link"] = feed_item["link"] if "link" in feed_item else ""

            feed.append(feed_item)

    return feed

# Recursively gets groups if pagination exists. In instances with a significant number of groups this
# may overflow the stack.
def getGroups(after=None):

    # Token-based auth header
    headers = {'Authorization': 'Bearer ' + TOKEN}

    # Fetch feed for each group, since a given time, but only get 1 feed item.
    # We'll use this later to check if there's fresh content in the group
    params = "?fields=feed.since(" + SINCE.strftime("%s") + ").limit(1),name,updated_time&amp;"

    # Default paging limit
    params += "&amp;limit=" + DEFAULT_LIMIT

    # Are we paging? Get the next page of data
    if after:
        params += "&amp;after=" + after

    graph_url = GRAPH_URL_PREFIX + "community" + GROUPS_SUFFIX + params

    result = requests.get(graph_url, headers=headers)
    result_json = json.loads(result.text, result.encoding)


    # Got an error? Ok let's break out
    if "error" in result_json:
        print "Error", result_json["error"]["message"]
        return []

    # Did we get back data?
    if "data" in result_json:
        for group_obj in result_json["data"]:
            # Only cache this group ID if there's fresh feed content
            if "feed" in group_obj:
                groups.append(group_obj)

    # Is there more data to page through? Recursively fetch the next page
    if json.dumps('"paging"') in result_json:
        getGroups(after=result_json["paging"]["cursors"]["after"])

    # Return an array of group IDs which have fresh content
    return groups
def encode(s):
    def safeStr(obj):
        try: return str(obj)
        except UnicodeEncodeError:
            return obj.encode('ascii', 'ignore').decode('ascii')
        return ""
    s = safeStr(s)
    return s

def strip(s):
    return re.sub(r'(?u)[^-\w.]', '', s)

for group in getGroups():
    feed = getFeed(group["id"], group["name"])

    # Create a new CSV named after the timestamp / group id / group name, to ensure uniqueness
    csv_filename = SINCE.strftime("%Y-%m-%d %H:%M:%S") + " " + group["id"] + " " + strip(group["name"]) + ".csv"
    if VERBOSE:
        print csv_filename
    else:
        print ".",

    with open(csv_filename, "wb") as csvfile:
        writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

        # CSV Header
        header = ["Post ID", "Permalink", "Create Time", "Updated Time", "Author", "Author ID", "Message", "Link", "reactions", "Comments"]
        writer.writerow(header)

        for item in feed:
            row = [ item["id"], item["permalink_url"], item["created_time"], item["updated_time"], encode(item["from"]["name"]), item["from"]["id"], encode(item["message"]), encode(item["link"]), item["reactions"]["summary"]["total_count"], item["comments"]["summary"]["total_count"]]
            if VERBOSE:
                print row
            writer.writerow(row)
