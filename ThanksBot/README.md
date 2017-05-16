# Thanks Bot for Workplace

## Database Setup

This bot uses a Postgres database for storing previous thanks events. To use the bot, create a database table table with the following fields:

* `create_date` (date)
* `permalink_url` (text)
* `recipient` (text)
* `recipient_manager` (text)
* `sender` (text)
* `message` (text)

You can create the table using the following command:

```
create table thanks (create_date date, permalink_url text, recipient text, recipient_manager text, sender text, message text);
```

## Installation

On the **Integrations** tab of the **Admin Dashboard**, create a custom integration app named "Thanks" with the following permissions:

* Read all groups
* Manage content

Obtain an access token and app secret and add them to the environment variables `ACCESS_TOKEN` and `APP_SECRET` respectively. Choose a verification token for securing your webhook URL (this can be any string) and add it to the `VERIFY_TOKEN` variable. Lastly, ensure that you have an environment variable for your `DATABASE_URL`.

Deploy the code to a node.js hosting service and use the **Edit custom integration** dialog to register a webhook subscription for the **Page** `mention` field. Use the path `https://{your host}/webhook` for your callback URL, and use whichever value you set for `VERIFY_TOKEN` above. **Note: Your server must be running in order to complete this step.**

## Usage

Mention the bot by name in a group post or comment, using the @-mention typeahead, then mention one or more employees and add a message describing the reason why they're being thanked. 

Example: 

> "**Thanks** **Connor Treacy** for providing clear installation instructions."

The bot should like the post, then follow up with a comment message mentioning the sender, recipient, and recipient's manager summarising recent 'thanks' stats.

## Summary Report

Go to `https://{your host}` to see a table of all thanks messages sent. 
