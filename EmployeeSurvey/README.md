# Employee Survey Sample App

This example shows how you can use quick replies to send a lightweight employee survey to an employee. 

Note: This sample app doesn't implement any data store; the implementation of storage is left to you.

## Deployment

To deploy this sample app, create a new [custom integration app](https://developers.facebook.com/docs/workplace/integrations/custom-integrations/apps) and set the `ACCESS_TOKEN` and `APP_SECRET` environment variables on your hosting accordingly. Set a value of your choosing for `VERIFY_TOKEN`, and start your web server. Then go to the Configure Webhooks section of the Edit App dialog and subscribe for the fields **mesage_deliveries**, **messaging_postbacks**, **message_reads** and **messages** under the **Page** tab.

## Usage

To trigger a survey request for a specific user, make a `GET` request to `/start/{user_id}`. In a production deployment, you'll want to start survey requests for specific users at well-defined times, and track their responses so you can remind them or re-invite them later.