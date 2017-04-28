## Managing Groups
  
**Language:** Python v2.7

This usecase demonstrates how to create [groups](/docs/workplace/custom-integrations/reference#groups) and manage their members. The example offers the following functionality:

* Getting a list of all groups with `id`, `name`, `privacy`, `description`, and `update_time`, by calling `getAllGroups(access_token, community_ID)`
* Getting the group members for a specific group by calling `getGroupMembers(access_token, group_id)`
* Add a member to a group by their email address by calling `addMemberToGroup(access_token, group_id, email)`
* Remove a member from a group by their email address by calling `removeMemberFromGroup(access_token, group_id, email)`
* Creating a group by calling `createNewGroup(access_token, name, description, privacy, administrator=None)`

To run this script, save the code as `manage_groups.py`. When prompted enter the values for the access token, community id, group name, group description, group privacy, administrator email address, and member email address. Run the script in a command line as follows:

python manage_groups.py

A group will be created with the name, description, privacy, and administrator provided. After the group is created the member with the member email address provided will be added to the group.
