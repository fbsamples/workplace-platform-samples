# Account Management Example

This example illustrates how a local account management agent for Workplace would operate. In this example, account information is provided as CSV-formatted files, and synced to Workplace using the [Account Management API](https://developers.facebook.com/docs/workplace/account-management/api). 

The example client is capable of:

* `-c` - **Create**: this command will use the provided CSV file to create new accounts in Workplace.
* `-u` - **Update**: this command will use the provided CSV file to update existing accounts in Workplace.
* `-e` - **Export All**: this command will export all accounts in Workplace to a CSV file under the listed name.
* `-d` - **Delete**: this command will use the provided CSV file to delete accounts in Workplace. **Note: only accounts that have never been claimed can be deleted**.

To run the agent:

1. Install and configure Python 2.7
2. Install required module [requests](https://l.facebook.com/l.php?u=http%3A%2F%2Fdocs.python-requests.org%2Fen%2Fmaster%2F&h=ATN9J4kY0w8eAAsmN3tvw6JiIrKZC17LBEH0e-4imYZy2Tsnq9SxLiGt-f_FwucZIueJTcU_D0d52MGHG7Mt7iuXTVPmpbUI5z12EXJltWrlvRJFarUwrV1JHuyvqcyJn3ASDoxJvaSR-c_fOP4BRvmk6wA)
3. Check out the `AccountManagement` folder containing the following files:

    * **scim_agent.py** - the main agent file. This file deals with file operations and determines what operation to run based on supplied command argument.
    * **scim_sdk.py** - python SDK for [Account Management API](https://developers.facebook.com/docs/workplace/account-management/api). Makes HTTP calls to API and has helper functions for parsing and handling data.
    * **csv_header.py** - definitions for headers used in the different input CSV files.

1. Run the agent from the location of the unzipped python files using one of the formats:

```
python scim_agent.py `command` `file`
python scim_agent.py `command` `file` `access_token` `scim_url`
```

Example for updating users based on update.csv

```
python scim_agent.py -u update.csv
```