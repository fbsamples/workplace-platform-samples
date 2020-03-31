# Deploying this Claim Portal to Heroku

1. Get a free [Heroku account](https://signup.heroku.com/) if you haven't already.

2. Install the [Heroku toolbelt](https://toolbelt.heroku.com) which will let you launch, monitor and generally control your instances (and other services like databases) from the command line. Also install the [local Postgres tools](https://devcenter.heroku.com/articles/heroku-postgresql#local-setup)

3. [Install Node](https://nodejs.org), this will be our server environment. Then open up your terminal and make sure you're running the latest version of npm, installed globally (the ```-g``` switch):

    ```
    sudo npm install npm -g
    ```

4. Clone this project and switch into the project directory.

    ```
    git clone https://github.com/fbsamples/wp-claim-portal.git
    cd wp-claim-portal
    ```

5. Install Node dependencies.

    ```
    npm install
    ```

6. Create a new Heroku application and push the code to the cloud.

    ```
    $ heroku create
    Creating app... done, ⬢ mystic-wind-83
    Created http://mystic-wind-83.herokuapp.com/ | git@heroku.com:mystic-wind-83.git
    ```  


7. Create a Postgres database and attach it to the application
    ```
    heroku addons:create heroku-postgresql:hobby-dev -a <application name, e.g.: mystic-wind-83>
    ```

8. Connect to the database and create the required table.
    ```
    heroku pg:psql -a <application name>
    <application name>::DATABASE=> CREATE TABLE employees(id bigint PRIMARY KEY, employee_id VARCHAR (50) UNIQUE NOT NULL, answer1 VARCHAR (50) NOT NULL,answer2 VARCHAR (50) NOT NULL); 
    ```
    You can exit the psql application using Control(^)+D

9. Return to the repo root and distribute the application to Heroku
    ```
    cd ..
    git subtree push --prefix wp-claim-portal heroku master
    ```

10. Set your enviroment variables according to the values set on the Workplace integration

    ```
    heroku config:set PAGE_ACCESS_TOKEN="Bearer <value for Access Token>"
    ```


11. You should now be able to acces the claim portal at https://<application name,  e.g.: mystic-wind-83>.herokuapp.com

12. Connect to your Postgres database and add any employees to the `employees` table.
    ```
    heroku pg:psql -a <application name>
    <application name>::DATABASE=> ::DATABASE=> INSERT INTO employees VALUES (100034734373321, 'cp002','bird', 'box');
    ```
