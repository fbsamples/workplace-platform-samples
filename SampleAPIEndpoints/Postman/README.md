# Workplace From Facebook Platform API samples for Postman

This is a collection of API samples for Postman containing examples of Graph and SCIM API documentation.

- Log In/Sign-up for Workplace(https://www.facebook.com/workplace).
- [Custom Integrations](https://developers.facebook.com/docs/workplace/custom-integrations-new) are built using Workplace API to interact with Workplace using automation/bots. 
- To learn more about Workplace API and Integration features, refer to the [API documentation](https://developers.facebook.com/docs/workplace/reference).
- Please ensure you have granted appropriate [permissions](https://developers.facebook.com/docs/workplace/reference/permissions) to the Custom Integration App within workplace before you can use the calls in Postman.


# Postman Setup
- Follow the [Guide](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#importing-data-into-postman) to import collections to your Postman. 
- You can import the sample "Workplace API env" or create new environment from scratch in Postman.


## Variables
While using these samples, you will have to [configure variables](https://learning.postman.com/docs/sending-requests/variables/) to pass values to your calls. Within these examples variables are referenced within following three sections in Postman:
- Body
- Query Params
- Path Variable

### Examples
Variable names are meant to be self explanatory throught these collections in accordance with Developer documentation. Below are examples of some commonly used variables. 
 - access_token: Contains the access token of the Custom Integration App that you are using for calling the API.
 - user_id/user_id2: unique Workplace user id(referenced as id in the schema).
 - external_id: mandatory for emailless users(referenced as externalId in schema).
 - user_email: email id of a user on your instance.
 - peopleset_id: unique Workplace ID of a peopleset(referenced as id in the schema)
