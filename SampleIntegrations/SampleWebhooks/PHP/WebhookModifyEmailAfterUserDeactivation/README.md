# Webhook that modifies the user email address following their deactivation on Workplace
  
**Language:** PHP v7.2

## DESCRIPTION
This usecase example shows how to receive a webhook request when a [user](https://developers.facebook.com/docs/workplace/reference/graph-api/member) is deactivated on Workplace (manually or automatically) and how to modify the user email address afterwards appending a date to it. Example:

1. User A, whose email address is `userA@mydomain.com`, is deactivated on Workplace (manually or automatically).
2. Workplace notifies your webhook that User A has been deactivated.
3. The webhook code changes the email address of User A from `userA@mydomain.com` to `userA_2021-03-01@mydomain.com`. Note that `2021_03_01` would be the date of today.

It could solve for situations of email collision where new users inherit email addresses from old users.

## SETUP
* Create a custom integration in the section of Integrations from the Workplace admin panel and configure a webhook accordingly.
* Copy the verify token that will be needed to register/configure the webhook.
* Generate an access token, and copy both the app secret and the access token, that will be needed to replace in the code.
* Edit the code to add the required parameters and then save the code in your server as `webhook_deactivation_mod_user.php`. Information about the parameters below.

### PARAMETERS
Here are the details of the script parameters to be replaced:

   | Parameter         | Description                                                |  Type           |  Required    | 
   |:-----------------:|:----------------------------------------------------------:|:---------------:|:------------:|
   | access_token      |  The access token of the Workplace integration             | _String_ | Yes |
   | app_secret      |  The app secret of the Workplace integration            | _String_ | Yes |
   | my_verify_token      |  The verify token that you define when registering your webhook           | _String_ | Yes |

### CREATE/CONFIGURE WEBHOOK ON WORKPLACE
More information on how to create an integration with the webhook functionality can be found in [this link](https://developers.facebook.com/docs/workplace/reference/webhooks/). You will need to create the integration and then register a webhook that can at least receive the events from "admin_activity", under the category of "Security".
To do so, you will need to add the callback url of your server, and an arbitrary verify token that needs to be the same on Workplace and in the webhook script.

### GENERATE ACCESS TOKEN
More information on how to generate an access token on Workplace can be found in [this link](https://developers.facebook.com/docs/workplace/custom-integrations-new/). The integration that you just created for the webhook should at least have the following permissions: "Read user email addresses", "Read security logs", "Read work profile" and "Manage work profiles".

## RUN
Once the webhook script is placed in your server and registered on Workplace, its code will run every time a user is deactivated on Workplace. It will trigger the change of email address for that user.

