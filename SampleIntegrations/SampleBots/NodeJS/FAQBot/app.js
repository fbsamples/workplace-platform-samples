
/* jshint node: true, devel: true */
'use strict';

/* Require dependencies */
const express = require('express'),
      bodyParser = require('body-parser'),
      crypto = require('crypto'),
      request = require('request');

/* Loads dependencies */
const config = require('./config/variables.js'),
      validators = require('./quicklinks/webhook-validators.js')(config),
      graph = require('./quicklinks/graph-methods.js')(request, config),
      encryption = require('./utilities/encryption.js')(crypto, config),
      messages = require('./utilities/messages.js')(graph);

/* Create express app */
const app = express();

/* Run app */
app.set('port', process.env.PORT || 5000);
app.set('view engine', 'ejs');
app.use(bodyParser.json({ verify: encryption._signCheck }));
app.use(express.static('public'));
app.listen(app.get('port'), () => {
  console.log('WP Hello app listening on port ' + app.get('port') + '!');
});

/* Setup default webhook endpoints */
validators._setupHeartbeat(app); //set up heartbeat endpoint
validators._setupTokenCheck(app); //set up token validation endpoints

/* Handle webhook payloads from Facebook */
app.post('/webhook', function(request, response) {
  let msgs = messages._getMessages(request);
  for(let msg of msgs) messages._handleMessage(msg);
  response.sendStatus(200);
});
