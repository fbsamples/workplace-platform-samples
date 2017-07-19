# Basic Webhooks Example

A basic [node.js](https://nodejs.org) implementation of a Webhook callback endpoint, which captures webhooks from Workplace and logs the details to the console.

This example uses [Express.js](https://www.npmjs.com/package/express) for URL routing, [crypto](https://www.npmjs.com/package/crypto) for verifying webhook signatures, and [body-parser](https://www.npmjs.com/package/body-parser) for parsing inbound `POST` payloads to JSON.

To configure this example, you'll need to create a new [custom integration](https://developers.facebook.com/docs/workplace/integrations/custom-integrations), then use the `ACCESS_TOKEN ` and `APP_SECRET` as shown for your new custom integration. You'll also need to set a `VERIFY_TOKEN`, which can be any string you like, and which is used to verify that the webhook subscription request came from Facebook.

To run this example, deploy to a node.js hosting solution and set up the `VERIFY_TOKEN`, `ACCESS_TOKEN` and `APP_SECRET` environment variables from above. If you want to run locally, create a `.env` file in the same directory as `app.js` and populate it with the environment variables, then use [ngrok.io](https://ngrok.io) to create a HTTPS public URL to your local machine.
