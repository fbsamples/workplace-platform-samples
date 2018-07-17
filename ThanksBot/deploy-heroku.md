# Deploying this Thanks Bot to Heroku


1. Get a free [Heroku account](https://signup.heroku.com/) if you haven't already.

2. Install the [Heroku toolbelt](https://toolbelt.heroku.com) which will let you launch, monitor and generally control your instances (and other services like databases) from the command line.

3. [Install Node](https://nodejs.org), this will be our server environment. Then open up Terminal (or whatever your CLI might be) and make sure you're running the latest version of npm, installed globally (the ```-g``` switch):

    ```
    sudo npm install npm -g
    ```

4. Clone this project and switch into the project directory.

    ```
    git clone https://github.com/eduardogomes/workplace-platform-samples.git
    cd ThanksBot
    ```

5. Install Node dependencies.

    ```
    npm install
    ```

6. Heroku requires this project to be 

6. Create a new Heroku application and push the code to the cloud.

    ```
    $ heroku create
    Creating app... done, ⬢ mystic-wind-83
    Created http://mystic-wind-83.herokuapp.com/ | git@heroku.com:mystic-wind-83.git
    $ heroku buildpacks:set heroku/nodejs
    ```  


7. Create a Postgres database and attach it to the application
    ```
    heroku addons:create heroku-postgresql:hobby-dev -a <application namne>
    ```

8. Connect to the database and create the required table.
    ```
    heroku pg:psql -a <application name>
    <application name>::DATABASE=>create table thanks (create_date date, permalink_url text, recipient text, recipient_manager text, sender text, message text);
    ```
    You can exit the psql application using Control(^)+D

8. Distribute the application 
    ```
    git push heroku master
    ```

7. You should be all set and be able to visit your page at the URL that was output by ```$ heroku create```.
