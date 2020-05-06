# Workplace From Facebook Platform API samples for Postman

This is a collection of API samples for Postman containing examples of Graph and SCIM API documentation.

To learn more about the Graph API of Workplace, check out the developer documentation at [https://developers.facebook.com/docs/workplace/reference/graph-api](https://developers.facebook.com/docs/workplace/reference/graph-api).

To learn more about the SCIM API of Workplace, check out the developer documentation at [https://developers.facebook.com/docs/workplace/reference/account-management-api](https://developers.facebook.com/docs/workplace/reference/account-management-api).

To get started using Workplace, go to [https://www.facebook.com/workplace](https://www.facebook.com/workplace).

# Postman Setup
While using these samples, you will have to [configure variables](https://learning.postman.com/docs/postman/variables-and-environments/variables/#defining-variables) to pass values to your calls. Within these examples variables are referenced within following three sections:
- Body
- Query Params
- Path Variable

## variables used
 - access_token: Contains the access token from the [custom integration](https://developers.facebook.com/docs/workplace/integrations/custom-integrations/apps/) in Workplace. Since its SCIM API, you will have to grant appropriate user management permissions to the app within workplace before you can use the calls in Postman. It should be configured within env variables for ease of use.
 - user_id/user_id2: unique Workplace user id(referenced as id in the schema).
 - external_id: mandatory for emailless users(referenced as externalId in schema).
 - user_email: email id of a user on your instance.
 - peopleset_id: unique Workplace ID of a peopleset(referenced as id in the schema)
