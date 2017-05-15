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
 * set them using environment variables or modifying the config file in /config.
 *
 */
// App Secret can be retrieved from the App Dashboard
// Verify_Token is defined by Developer
// Accesstoken is given when creating the app
// Server Url is the NodeJS Url
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
function simpleWebserviceCall(event) {
	var senderID = event.sender.id;
	var message = event.message;

	console.log('Received message from user %d with message:', senderID);
	console.log(JSON.stringify(message));

  // create message Object
	var messageData = {
		recipient: {
			id: senderID
		},
		message: {
			text: ''
		}
	};

	// use request repo
	// https://github.com/request/request
	// 
	// request({
	// 	uri: '',
	// 	qs: { m: message.text },
	// 	headers: {
	// 		'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
	// 	}
	// }

	request({
		uri: 'http://swapi.co/api/starships',
	}, function (error, response, body) {
		if(error) {
			messageData.message.body = 'Sorry, I\'m not well';
		} else {

			var data = JSON.parse(body);

			console.log('Data came back from Endpoint Backend.');
			console.log(data);

			if(data.answers.length) {
				for( var i in data.answers) {
					messageData.message.text = data.answers[i].slice(0, 640);
					callSendAPI(messageData);
				}
			} else {
				messageData.message.text = 'Sorry, we dont have a result for you atm';
				callSendAPI(messageData);
			}
		}
	});

	return;
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
	var signature = req.headers['x-hub-signature'];

	if (!signature) {
    // For testing, let's log an error. In production, you should throw an 
    // error.
		console.error('Couldn\'t validate the signature.');
	} else {
		var elements = signature.split('=');
		var signatureHash = elements[1];

		var expectedHash = crypto.createHmac('sha1', APP_SECRET).update(buf).digest('hex');

		if (signatureHash != expectedHash) {
			throw new Error('Couldn\'t validate the request signature.');
		}
	}
}

/*
 * Use your own validation token. Check that the token used in the Webhook 
 * setup is the same token used here.
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

      // Iterate over each messaging event
			pageEntry.messaging.forEach(function(messagingEvent) {
				if (messagingEvent.message) {
					simpleWebserviceCall(messagingEvent);
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
			var recipientID = body.recipient_id;
			var messageId = body.message_id;

			if (messageId) {
				console.log('Successfully sent message with id %s to recipient %s', messageId, recipientID);
			} else {
				console.log('Successfully called Send API for recipient %s', recipientID);
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