# Generic Bot framework for Workplace

Generic bot that captures both page and group webhook events and provides corresponding action
functions. This program uses a simple emoji removal function as an end-point but it can be
easily replaced with a more complex/interesting entry into conversational system.

## Installation

On the **Integrations** tab of the **Admin Dashboard**, create a custom integration app.

The permissions for the app as well as webhook should correspond to the functionality you
are trying to implement.

Look at fbWebhookPost function in app.js as it is important to make sure admin settings map to
corresponding code.

Finally, make sure to copy ACCESS_TOKEN, APP_SECRET and VERIFY_TOKEN from the admin panel and
set corresponding environment variables before running the code.

Deploy the code to a node.js, either in local environment and exposing the node port to FB through
localtunnel.me (which gives HTTPS web end-point necessary for workplace to communicate with) or
through hosting service like Heroku.

For a local setup, these steps should get things working -

1) Set environment variables - APP_TOKEN, APP_SECRET and VERIFY_TOKEN
2) Deploy node service by running: node app.js - By default, node server will be running on port 5000
3) Run localtunnel to expose HTTPS/SSL end-point: lt --port 5000 - Copy the URL presented by localtunnel
4) Go to FB Workplace Dashboard -> Integrations -> Custom integration and configure "Permissions" and
   "Webhooks" pages with corresponding settings
5) If everything goes well, you will see "Validated webhook" message
6) Now direct message to bot with a text and an emoji and bot will respond with identical text but
   without the emoji. Similarly, new posts/comments with emojis in Workplace groups will cause bot to
   respond as a comment with the same text without the emoji
7) Alter code to build your own bot(s).


Have fun!