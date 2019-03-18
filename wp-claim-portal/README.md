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

### Usage and Security remarks
This is sample solution, provided as-is, without guarantee or support. You can use this solution for learning purposes or build upon and maintain it.

One recommend improvement is around the security answers stored and compared in clear-text. A potential solution should store and compare them as hashes. Using the [bcrypt-nodejs library](https://www.npmjs.com/package/bcrypt-nodejs), you can get this result storing both hashes on the `employees` table

```
npm install bcrypt
…
var bcrypt = require('bcrypt');
var hash1 = bcrypt.hashSync(<security answer1>);
var hash2 = bcrypt.hashSync(<security answer2>);
```

And change [these lines](https://github.com/fbsamples/workplace-platform-samples/blob/80a2e2ddb6b785dbc46a719e57a69c293c0fa0e4/wp-claim-portal/app/controllers/security_questions.js#L30-L31) to:

```
    if (bcrypt.compareSync(security_questions[0],res.rows[0].answer1) &&
      bcrypt.compareSync(security_questions[1],res.rows[0].answer2){
```

Refer to [OWASP cheat sheets](https://github.com/OWASP/CheatSheetSeries/blob/master/Index.md) for a compreensive list of security recommendations for web applications.
