# Sample Claim Portal for Workplace

A Claim Portal is a simple web page that e-mailless users can access to confirm their data and receive a Workplace access code.

*Claim portal requires the **Manage account** permission*

## Database Setup

This portal uses a Postgres database for storing the security questions. To use the portal, create a database table with the following fields:

* `id` (bigint) - The Workplace User ID
* `employee_id` (text) - The Employee known ID 
* `answer1` (text) - A secret both the company and the employee know (e.g.: personal document number)
* `answer2` (text) - A second secret both the company and the employee know (e.g.: mother's name)

You can create the table using the following command:

```
CREATE TABLE employees(id bigint PRIMARY KEY, employee_id VARCHAR (50) UNIQUE NOT NULL, answer1 VARCHAR (50) NOT NULL,answer2 VARCHAR (50) NOT NULL); 
```

## Installation

### Deploy the Claim Portal
Deploy the code to a node.js hosting service as [Heroku](deploy-heroku.md).

On the **Integrations** tab of the **Admin Dashboard**, create a custom integration app named "Claim Portal" with the **Manage accounts** permission.

Obtain an access token and add them to the environment variable `PAGE_ACCESS_TOKEN`. Ensure that you have an environment variable for your `DATABASE_URL`.

### Load your employee data on the Postgres `employee` table. 

[Export your provisioned employees](https://work.workplace.com/help/work/1858663031075098) from Workplace. This claim portal only support users [provisioned with access codes](https://work.workplace.com/help/work/546217199128952). 

Populate the `employees` Postgres table with the information provisioned to Workplace (`id` and `employee_id`) and the secrets your company shares with the employee (`answer1` and `answer2`). These secrets will be used to confirm an employee identity before providing them an access code.
