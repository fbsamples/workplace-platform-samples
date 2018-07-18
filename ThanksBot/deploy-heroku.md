# Deploying this Thanks Bot to Heroku


1. Get a free [Heroku account](https://signup.heroku.com/) if you haven't already.

2. Install the [Heroku toolbelt](https://toolbelt.heroku.com) which will let you launch, monitor and generally control your instances (and other services like databases) from the command line. Also install the [local Postgres tools](https://devcenter.heroku.com/articles/heroku-postgresql#local-setup)

3. [Install Node](https://nodejs.org), this will be our server environment. Then open up your terminal and make sure you're running the latest version of npm, installed globally (the ```-g``` switch):

    ```
    sudo npm install npm -g
    ```

4. Clone this project and switch into the project directory.

    ```
    git clone https://github.com/fbsamples/workplace-platform-samples.git
    cd ThanksBot
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
    <application name>::DATABASE=>create table thanks (create_date date, permalink_url text, recipient text, recipient_manager text, sender text, message text);
    ```
    You can exit the psql application using Control(^)+D

9. Return to the repo root and distribute the application to Heroku
    ```
    cd ..
    git subtree push --prefix ThanksBot heroku master
    ```

10. Set your enviroment variables according to the values set on the Workplace integration
 ![Workplace Integration](https://github.com/fbsamples/workplace-platform-samples/blob/master/ThanksBot/public/img/integration.png)

    ```
    heroku config:set APP_SECRET=<value for App Secret, 1 on image above>
    heroku config:set ACCESS_TOKEN=<value for Access Token, 2 on image above>
    heroku config:set VERIFY_TOKEN=<value for Verify Token, 3 on image above>
    ```

    Also set the permissions (Mention Bot, Read group content and Manage Group Content), the callback URL on Workplace (https://<application name,  e.g.: mystic-wind-83>.herokuapp.com/webhook) and "mention" subscription field.

11. You should now be able to mention your integration, tag a Workplace member and receive the Thanks mention. A summary of the thanks sent is available at https://<application name,  e.g.: mystic-wind-83>.herokuapp.com
