/*
 * Copyright 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

/* jshint node: true, devel: true */
'use strict';

const 
  bodyParser = require('body-parser'),
  config = require('config'),
  crypto = require('crypto'),
  express = require('express'),
  https = require('https'),  
  request = require('request');

var app = express();
app.set('port', process.env.PORT || 5000);
app.set('view engine', 'ejs');
app.use(bodyParser.json({ verify: verifyRequestSignature }));
app.use(express.static('public'));

/*
 * Be sure to setup your config values before running this code. You can 
 * set them using environment variables or modifying the config file in /config.
 *
 */
// App ID can be retrieved from /app with page token
const APP_ID = (process.env.APP_ID) ? 
  process.env.APP_ID :
  config.get('appId');

// App Secret can be retrieved from the App Dashboard
const APP_SECRET = (process.env.MESSENGER_APP_SECRET) ? 
  process.env.MESSENGER_APP_SECRET :
  config.get('appSecret');

// Arbitrary value used to validate a webhook
const VALIDATION_TOKEN = (process.env.MESSENGER_VALIDATION_TOKEN) ?
  (process.env.MESSENGER_VALIDATION_TOKEN) :
  config.get('validationToken');

// Generate a page access token for your page from the App Dashboard
const PAGE_ACCESS_TOKEN = (process.env.MESSENGER_PAGE_ACCESS_TOKEN) ?
  (process.env.MESSENGER_PAGE_ACCESS_TOKEN) :
  config.get('pageAccessToken');

// URL where the app is running (include protocol). Used to point to scripts and 
// assets located at this address. 
const SERVER_URL = (process.env.SERVER_URL) ?
  (process.env.SERVER_URL) :
  config.get('serverURL');

if (!(APP_SECRET && VALIDATION_TOKEN && PAGE_ACCESS_TOKEN && SERVER_URL)) {
  console.error("Missing config values");
  process.exit(1);
}

const GRAPH_API_BASE = 'https://graph.facebook.com/v2.6';

// Enable page subscriptions for this app, using the app-page token
function enableSubscriptions() {
  request({
    baseUrl: GRAPH_API_BASE,
    method: 'POST',
    url: '/me/subscribed_apps',
    auth: {'bearer' : PAGE_ACCESS_TOKEN}
  },function(error,response,body){
    // This should return with {success:true}, otherwise you've got problems!
    console.log('enableSubscriptions',body);
  });
}

function subscribeWebhook() {
  request({
    baseUrl: GRAPH_API_BASE,
    auth: {'bearer' : APP_ID + '|' + APP_SECRET},
    url: '/app/subscriptions',
    method: 'POST',
    qs: {
      'object': 'page',
      'fields': 'mention,message_deliveries,messages,messaging_postbacks,messaging_optins',
      'include_values': 'true',
      'verify_token': VALIDATION_TOKEN,
      'callback_url': SERVER_URL + '/webhook'
    },
  }, function (error, response, body) {
    console.log('subscribeWebhook',response.body);
  });  
}

/*
 * Verify that the callback came from Facebook. Using the App Secret from 
 * the App Dashboard, we can verify the signature that is sent with each 
 * callback in the x-hub-signature field, located in the header.
 *
 * https://developers.facebook.com/docs/graph-api/webhooks#setup
 *
 */
function verifyRequestSignature(req, res, buf) {
  var signature = req.headers["x-hub-signature"];

  if (!signature) {
    // For testing, let's log an error. In production, you should throw an 
    // error.
    console.error("Couldn't validate the signature.");
  } else {
    var elements = signature.split('=');
    var method = elements[0];
    var signatureHash = elements[1];

    var expectedHash = crypto.createHmac('sha1', APP_SECRET)
                        .update(buf)
                        .digest('hex');

    if (signatureHash != expectedHash) {
      throw new Error("Couldn't validate the request signature.");
    }
  }
}

app.get('/start/:user', function(req, res) {
	console.log('Start', req.params.user);
	sendStartSurvey(req.params.user);
	res.sendStatus(200);
});

/*
 * Use your own validation token. Check that the token used in the Webhook 
 * setup is the same token used here.
 *
 */
app.get('/webhook', function(req, res) {
  if (req.query['hub.mode'] === 'subscribe' &&
      req.query['hub.verify_token'] === VALIDATION_TOKEN) {
    console.log("Validating webhook");
    res.status(200).send(req.query['hub.challenge']);
  } else {
    console.error("Failed validation. Make sure the validation tokens match.");
    res.sendStatus(403);          
  }  
});

/*
 * All callbacks for Messenger are POST-ed. They will be sent to the same
 * webhook. Be sure to subscribe your app to your page to receive callbacks
 * for your page. 
 * https://developers.facebook.com/docs/messenger-platform/product-overview/setup#subscribe_app
 *
 */
app.post('/webhook', function (req, res) {
  var data = req.body;

  // Make sure this is a page subscription
  if (data.object == 'page') {
    // Iterate over each entry
    // There may be multiple if batched
    data.entry.forEach(function(pageEntry) {
      var pageID = pageEntry.id;
      var timeOfEvent = pageEntry.time;

      // Iterate over each messaging event
      pageEntry.messaging.forEach(function(messagingEvent) {
        if (messagingEvent.optin) {
          receivedAuthentication(messagingEvent);
        } else if (messagingEvent.message) {
          receivedMessage(messagingEvent);
        } else if (messagingEvent.delivery) {
          receivedDeliveryConfirmation(messagingEvent);
        } else if (messagingEvent.postback) {
          receivedPostback(messagingEvent);
        } else if (messagingEvent.read) {
          receivedMessageRead(messagingEvent);
        } else if (messagingEvent.account_linking) {
          receivedAccountLink(messagingEvent);
        } else {
          console.log("Webhook received unknown messagingEvent: ", messagingEvent);
        }
      });
    });

    // Assume all went well.
    //
    // You must send back a 200, within 20 seconds, to let us know you've 
    // successfully received the callback. Otherwise, the request will time out.
    res.sendStatus(200);
  }
});

/*
 * Message Event
 *
 * This event is called when a message is sent to your page. The 'message' 
 * object format can vary depending on the kind of message that was received.
 * Read more at https://developers.facebook.com/docs/messenger-platform/webhook-reference/message-received
 *
 * For this example, we're going to echo any text that we get. If we get some 
 * special keywords ('button', 'generic', 'receipt'), then we'll send back
 * examples of those bubbles to illustrate the special message bubbles we've 
 * created. If we receive a message with an attachment (image, video, audio), 
 * then we'll simply confirm that we've received the attachment.
 * 
 */
function receivedMessage(event) {
  var senderID = event.sender.id;
  var recipientID = event.recipient.id;
  var timeOfMessage = event.timestamp;
  var message = event.message;

  console.log("Received message for user %d and page %d at %d with message:", 
    senderID, recipientID, timeOfMessage);
  console.log(JSON.stringify(message));

  var isEcho = message.is_echo;
  var messageId = message.mid;
  var appId = message.app_id;
  var metadata = message.metadata;

  // You may get a text or attachment but not both
  var messageText = message.text;
  var messageAttachments = message.attachments;
  var quickReply = message.quick_reply;

  if (isEcho) {
    // Just logging message echoes to console
    console.log("Received echo for message %s and app %d with metadata %s", 
      messageId, appId, metadata);
    return;
  } else if (quickReply) {
    var quickReplyPayload = quickReply.payload;
    console.log("Quick reply for message %s with payload %s",
      messageId, quickReplyPayload);

    var payload_tokens = quickReplyPayload.split(':');
	var payload_action = payload_tokens[0];
	var payload_object = payload_tokens[1];

    switch (payload_action) {
      case 'DELAY_SURVEY':
        sendDelaySurvey(senderID);
        break;
      case 'START_SURVEY':
        sendFirstQuestion(senderID);
        break;
      case 'HAPPY':
        sendSecondQuestion(senderID);
        break;
      case 'STAY':
        sendThankYou(senderID);
        break;
      default:
        console.log('Quick reply tapped', senderID, quickReplyPayload);
        break;
    }
    return;
  }
}

/*
 * Send a text message using the Send API.
 *
 */
function sendTextMessage(recipientId, messageText) {
  var messageData = {
    recipient: {
      id: recipientId
    },
    message: {
      text: messageText,
      metadata: "DEVELOPER_DEFINED_METADATA"
    }
  };

  callSendAPI(messageData);
}

/*
 * Send a message with Quick Reply buttons.
 *
 */
function sendStartSurvey(recipientId) {
  request({
    baseUrl: GRAPH_API_BASE,
    url: '/' + recipientId,
    qs: {
    	'fields': 'first_name'
    },
    auth: {'bearer' : PAGE_ACCESS_TOKEN}
  },function(error,response,body){
    body = JSON.parse(body);
    var messageData = {
      recipient: {
        id: body.id
      },
      message: {
        text: "Hi " + body.first_name + ", your opinion matters to us. Do you have a few seconds to answer a quick survey?",
        quick_replies: [
          {
            "content_type":"text",
            "title":"Yes",
            "payload":"START_SURVEY"
          },
          {
            "content_type":"text",
            "title":"Not now",
            "payload":"DELAY_SURVEY"
          }
        ]
      }
    };

    callSendAPI(messageData);
  });
}

/*
 * Send a text message using the Send API.
 *
 */
function sendDelaySurvey(recipientId) {
  var messageData = {
    recipient: {
      id: recipientId
    },
    message: {
      text: "No problem, we'll try again tomorrow"
    }
  };

  callSendAPI(messageData);
}

/*
 * Send a text message using the Send API.
 *
 */
function sendThankYou(recipientId) {
  var messageData = {
    recipient: {
      id: recipientId
    },
    message: {
      text: "Thanks for your feedback! If you have any other comments, write them below."
    }
  };

  callSendAPI(messageData);
}

/*
 * Send a message with Quick Reply buttons.
 *
 */
function sendFirstQuestion(recipientId) {
  var messageData = {
    recipient: {
      id: recipientId
    },
    message: {
      text: "Between 1 and 5, where 5 is 'Very Happy', how happy are you working here?",
      quick_replies: [
        {
          "content_type":"text",
          "title":"☹️ 1",
          "payload":"HAPPY:1"
        },
        {
          "content_type":"text",
          "title":"2",
          "payload":"HAPPY:2"
        },
        {
          "content_type":"text",
          "title":"3",
          "payload":"HAPPY:3"
        },
        {
          "content_type":"text",
          "title":"4",
          "payload":"HAPPY:4"
        },
        {
          "content_type":"text",
          "title":"5 😃",
          "payload":"HAPPY:5"
        }
      ]
    }
  };

  callSendAPI(messageData);
}

/*
 * Send a message with Quick Reply buttons.
 *
 */
function sendSecondQuestion(recipientId) {
  var messageData = {
    recipient: {
      id: recipientId
    },
    message: {
      text: "How long do you plan to stay in the company?",
      quick_replies: [
        {
          "content_type":"text",
          "title":"0-1 years",
          "payload":"STAY:1"
        },
        {
          "content_type":"text",
          "title":"1-2 years",
          "payload":"STAY:2"
        },
        {
          "content_type":"text",
          "title":"2-4 years",
          "payload":"STAY:3"
        },
        {
          "content_type":"text",
          "title":"5+ years",
          "payload":"STAY:4"
        }
      ]
    }
  };

  callSendAPI(messageData);
}

/*
 * Call the Send API. The message data goes in the body. If successful, we'll 
 * get the message id in a response 
 *
 */
function callSendAPI(messageData) {
  request({
  	baseUrl: GRAPH_API_BASE,
    url: '/me/messages',
    qs: { access_token: PAGE_ACCESS_TOKEN },
    method: 'POST',
    json: messageData

  }, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      var recipientId = body.recipient_id;
      var messageId = body.message_id;

      if (messageId) {
        console.log("Successfully sent message with id %s to recipient %s", 
          messageId, recipientId);
      } else {
      console.log("Successfully called Send API for recipient %s", 
        recipientId);
      }
    } else {
      console.error("Failed calling Send API", response.statusCode, response.statusMessage, body.error);
    }
  });  
}

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid 
// certificate authority.
app.listen(app.get('port'), function() {
  console.log('Node app is running on port', app.get('port'));
  enableSubscriptions();
  subscribeWebhook();
});

module.exports = app;