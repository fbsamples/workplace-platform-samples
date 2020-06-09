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
	crypto = require('crypto'),
	express = require('express'),
	request = require('request');

var app = express();
app.set('port', process.env.PORT || 5000);
app.set('view engine', 'ejs');
app.use(bodyParser.json({ verify: verifyRequestSignature }));
app.use(express.static('public'));

/*
 * Be sure to setup your config values before running this code. You can 
 * set them using environment variables.
 * 
 * https://developers.facebook.com/docs/workplace/integrations/custom-integrations/apps
 *
 */
const
	APP_SECRET = process.env.APP_SECRET,
	VERIFY_TOKEN = process.env.VERIFY_TOKEN,
	ACCESS_TOKEN = process.env.ACCESS_TOKEN,
	SERVER_URL = (process.env.SERVER_URL);

if (!(APP_SECRET && VERIFY_TOKEN && ACCESS_TOKEN && SERVER_URL)) {
	console.error('Missing environment variables');
	process.exit(1);
}

const GRAPH_API_BASE = 'https://graph.facebook.com/v2.6';

/*
 * Verify that the callback came from Facebook. Using the App Secret from 
 * your custom integration, we can verify the signature that is sent with each 
 * callback in the x-hub-signature field, located in the header.
 *
 * https://developers.facebook.com/docs/workplace/integrations/custom-integrations/apps
 *
 */
function verifyRequestSignature(req, res, buf) {
	var signature = req.headers['x-hub-signature'];

	if (!signature) {
		// For testing, let's log an error. In production, you should throw an 
		// error.
		console.error("Couldn't validate the signature.");
	} else {
		var elements = signature.split('=');
		var signatureHash = elements[1];

		var expectedHash = crypto.createHmac('sha1', APP_SECRET).update(buf).digest('hex');

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
 * Use your own validation token. This can be any string. Check that the 
 * token used in the Webhook setup is the same token used here.
 *
 */
app.get('/webhook', function(req, res) {
	if (req.query['hub.mode'] === 'subscribe' &&
			req.query['hub.verify_token'] === VERIFY_TOKEN) {
		console.log('Validating webhook');
		res.status(200).send(req.query['hub.challenge']);
	} else {
		console.error('Failed validation. Make sure the validation tokens match.');
		res.sendStatus(403);          
	}  
});

/*
 * All callbacks for webhooks are POST-ed. They will be sent to the same
 * webhook URL. Be sure to subscribe your app to your page to receive callbacks
 * for your page.
 * 
 * https://developers.facebook.com/docs/workplace/integrations/custom-integrations/apps
 */
app.post('/webhook', function (req, res) {
	var data = req.body;

	// Make sure this is a page subscription
	if (data.object == 'page') {
		// Iterate over each entry
		// There may be multiple if batched
		data.entry.forEach(function(pageEntry) {

			// Iterate over each messaging event
			pageEntry.messaging.forEach(function(messagingEvent) {
				if (messagingEvent.message) {
					receivedMessage(messagingEvent);
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
 */
function receivedMessage(event) {
	var senderID = event.sender.id;
	var recipientID = event.recipient.id;
	var timeOfMessage = event.timestamp;
	var message = event.message;

	console.log('Received message for user %d and page %d at %d with message:', 
		senderID, recipientID, timeOfMessage);
	console.log(JSON.stringify(message));

	var isEcho = message.is_echo;
	var messageId = message.mid;
	var appId = message.app_id;
	var metadata = message.metadata;

	// You may get a text or attachment but not both
	var quickReply = message.quick_reply;

	if (isEcho) {
		// Just logging message echoes to console
		console.log('Received echo for message %s and app %d with metadata %s', 
			messageId, appId, metadata);
		return;
	} else if (quickReply) {
		var quickReplyPayload = quickReply.payload;
		console.log('Quick reply for message %s with payload %s',
			messageId, quickReplyPayload);

		var payload_tokens = quickReplyPayload.split(':');
		var payload_action = payload_tokens[0];

		// We're using predefined metadata payloads for the quickreply messages
		// so let's use these to understand what should happen next
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
		auth: {'bearer' : ACCESS_TOKEN}
	},function(error,response,body){
		body = JSON.parse(body);
		var messageData = {
			recipient: {
				id: body.id
			},
			message: {
				text: `Hi ${body.first_name}, your opinion matters to us. Do you have a few seconds to answer a quick survey?`,
				quick_replies: [{
					content_type: 'text',
					title: 'Yes',
					payload: 'START_SURVEY'
				},{
					content_type: 'text',
					title: 'Not now',
					payload: 'DELAY_SURVEY'
				}]
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
			text: 'Thanks for your feedback! If you have any other comments, write them below.'
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
			quick_replies: [{
				content_type: 'text',
				title: '☹️ 1',
				payload: 'HAPPY:1'
			},{
				content_type: 'text',
				title: '2',
				payload: 'HAPPY:2'
			},{
				content_type: 'text',
				title: '3',
				payload: 'HAPPY:3'
			},{
				content_type: 'text',
				title: '4',
				payload: 'HAPPY:4'
			},{
				content_type: 'text',
				title: '5 😃',
				payload: 'HAPPY:5'
			}]
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
			text: 'How long do you plan to stay in the company?',
			quick_replies: [{
				content_type: 'text',
				title: '0-1 years',
				payload: 'STAY:1'
			},{
				content_type: 'text',
				title: '1-2 years',
				payload: 'STAY:2'
			},{
				content_type: 'text',
				title: '2-4 years',
				payload: 'STAY:3'
			},{
				content_type: 'text',
				title: '5+ years',
				payload: 'STAY:4'
			}]
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
		qs: { access_token: ACCESS_TOKEN },
		method: 'POST',
		json: messageData

	}, function (error, response, body) {
		if (!error && response.statusCode == 200) {
			var recipientId = body.recipient_id;
			var messageId = body.message_id;

			if (messageId) {
				console.log('Successfully sent message with id %s to recipient %s', messageId, recipientId);
			} else {
				console.log('Successfully called Send API for recipient %s', recipientId);
			}
		} else {
			console.error('Failed calling Send API', response.statusCode, response.statusMessage, body.error);
		}
	});  
}

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid 
// certificate authority.
app.listen(app.get('port'), function() {
	console.log('Node app is running on port', app.get('port'));
});

module.exports = app;
