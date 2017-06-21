/*
 * Copyright 2017-present, Facebook, Inc.
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
  request = require('request');


var app = express();
app.set('port', process.env.PORT || 5000);

app.get('/', function (req, res) {
        res.send('Hello world, I am a chat bot')
})

app.use('/webhook/facebook',bodyParser.json({ verify: verifyRequestSignature }));


/*
 * Be sure to setup your config values before running this code. You can 
 * set them using environment variables or modifying the config file in /config.
 *
 */
// App Secret can be retrieved from the App Dashboard
const APP_SECRET = (process.env.APP_SECRET) ? 
  process.env.APP_SECRET :
  config.get('Workplace.appSecret');

const APP_TOKEN = (process.env.APP_TOKEN) ? 
  process.env.APP_TOKEN :
  config.get('Workplace.appToken');

// Arbitrary value used to validate a webhook
const VERIFY_TOKEN = (process.env.VERIFY_TOKEN) ?
  (process.env.VERIFY_TOKEN) :
  config.get('Workplace.verifyToken');


if (!(APP_SECRET && APP_TOKEN && VERIFY_TOKEN )) {
  console.error("Missing config/environment values");
  process.exit(1);
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

var graphapi = request.defaults({
    baseUrl: 'https://graph.facebook.com',
    json: true,
    auth: {
        'bearer' : APP_TOKEN
    }
});

function fbWebhookGet(req, res) {
  if (req.query['hub.mode'] === 'subscribe' &&
    // This verify token string should match whatever you used when you subscribed for the webhook
    req.query['hub.verify_token'] === VERIFY_TOKEN) {
    console.log("Validated webhook");
    res.status(200).send(req.query['hub.challenge']);
  } else {
    console.error("Failed validation. Make sure the validation tokens match.");
    res.sendStatus(403);
  }   
}

/*
 * Below function is really the crux of how to intercept and trigger action on 
 * webhook events.
 *
 * This code ties to webhooks configurations on Workplace new app
 * integration page with an actual event generated at API level -
 * https://developers.facebook.com/docs/workplace/integrations/custom-integrations/webhooks
 * 
 * In a nutshell, there are two types of events that can enter this body
 * 1) Direct message to bot in chat/messaging and explicit mention of the bot
 *    (e.g. @mention) create page events, while
 * 2) New posts and comments on Groups (irrespective of bot itself) create 'group'
 *    events.
 * 
 * Below code separated each of the event and provides action function for each.
 * One can comment/uncomment specific piece of code to narrow the functionality
 * to only restricted set of events (e.g. chatbot in Workplace Chat). Moreover,
 * one can use replace emoji removal function to be an intry point to build more
 * interesting bot functionality.
*/

function fbWebhookPost(req, res) {
    // Uncomment below to see the JSON
    //console.log(JSON.stringify(req.body, null, 2));

    if(req.body && req.body.entry) {
	req.body.entry.forEach(function(entry) {
	    
	    if (req.body.object === 'page') {
		entry.messaging.forEach(function(messagingEvent) {
		    if (messagingEvent.message) {
			console.log("Received message");
			HandleMessages(messagingEvent);
		    }
		});
	    }
	    else if (req.body.object === 'group') {
		entry.changes.forEach(function(change) {
		if (change.field === 'mention') {
		    HandleMentions(change);
		} else if (change.field === 'posts') {
		    console.log("received post");
		    HandlePosts(change);
		} else if (change.field === 'comments') {
		    console.log("received comment");
		    HandleComments(change);
		} else {
		    console.log("Don't know whay kind of request this is", change.field);
		}	
		});	
	    }
	});
    }
    else {
	console.error('Webhook Callback',req.body);
    }
    // Always send back a 200 OK, otherwise Facebook will retry the callback later
    res.sendStatus(200);
}

function HandleMessages(event) {

    var senderid = event.sender.id;
    var message = event.message;
    var messageid = message.mid;

        if (message.text) {
        var clean_message = removeEmojis(message.text);
        if (clean_message) {
	    replyToSender(senderid, clean_message);
        }
    }
}


function HandleMentions(change) {

    if (change.value.item === 'comment') {
        var comment_id = change.value.comment_id;
        var comment_message = change.value.message;
        // Get the content of the parent post
        var post_id = change.value.post_id;
        graphapi({
            url: '/' + post_id,
            qs: { 'fields': 'message,permalink_url' }
        },function(error,response,body){
            //console.log(JSON.stringify(body, null, 2));
            if(body) {
                var clean_comment = removeEmojis(comment_message);
                if (clean_comment) {
                    replyToPostOrCommentId(comment_id, clean_comment);
                }
            }
        });
    } else if (change.value.item === 'post') {
        //mentioned in post
        var postid = change.value.post_id;
        // Get the content of the post
        graphapi({
            url: '/' + postid,
            qs: { 'fields': 'message,from{name,email},formatting,permalink_url' }
        },function(error,response,body){
          //  console.log(JSON.stringify(body, null, 2));
            if(body) {
                var clean_post = removeEmojis(body.message);
                if (clean_post) {
                    replyToPostOrCommentId(body.id, clean_post);
                }
            }
        });
    } else {
        // Not a mention webhook, do something else here
        console.log('Neither a comment not a post, dont know what to do');
    }
    
}

function HandlePosts(change) {

    var postid = change.value.post_id;
    var post_message = change.value.message;

    if (post_message) {
	var clean_post = removeEmojis(post_message);
	if (clean_post) {
	    replyToPostOrCommentId(postid, clean_post);
	}
    }
}

function HandleComments(change) {

    var commentid = change.value.comment_id;
    var comment_message = change.value.message;

    if (comment_message) {
        var clean_post = removeEmojis(comment_message);
        if (clean_post) {
            replyToPostOrCommentId(commentid, clean_post);
        }
    }
}


    
// This will be called by Facebook when the webhook is being subscribed
// Make sure you have your https://<ServerURL>/webhook/facebook as your webhook
// URL on App configuration page

app.get('/webhook/facebook', fbWebhookGet);

// Facebook webhook callbacks are done via POST
app.post('/webhook/facebook', fbWebhookPost);


var replyToPostOrCommentId = function(id, message) {
    console.log('Replying To Post Or Comment',id, message);
    graphapi({
        method: 'POST',
        url: '/' + id + '/comments',
        qs: {
            'message': message
        }
    },function(error,response,body){
        if(error) {
            console.error(error);
        }
    });
}

var replyToSender = function(recipientid, message) {
    console.log('Replying to message', recipientid, message);
    var messagePayload = {
	recipient: {
	    id: recipientid
	},
	message: {
	    text: message,
	}
    };
    callSendAPI (messagePayload);
}

/*
 * Call the Send API. The message data goes in the body. If successful, we'll
 * get the message id in a response
 *
 */
function callSendAPI(messageData) {
    graphapi({
        url: '/me/messages',
	//                qs: { access_token: ACCESS_TOKEN },
        method: 'POST',
        json: messageData
	
    }, function (error, response, body) {
	if(error) {
	    console.error(error);
	}
     });
}

/* This function removes Emojis from the sent text and returns the text 
 * without emojis.
 * Surprisingly, it isn't straightforward to detect all the different kind
 * of emojis - https://stackoverflow.com/questions/10992921/how-to-remove-emoji-code-using-javascript
 */

var removeEmojis = function(str) {

    var regex = /(?:[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff]|[\u0023-\u0039]\ufe0f?\u20e3|\u3299|\u3297|\u303d|\u3030|\u24c2|\ud83c[\udd70-\udd71]|\ud83c[\udd7e-\udd7f]|\ud83c\udd8e|\ud83c[\udd91-\udd9a]|\ud83c[\udde6-\uddff]|\ud83c[\ude01-\ude02]|\ud83c\ude1a|\ud83c\ude2f|\ud83c[\ude32-\ude3a]|\ud83c[\ude50-\ude51]|\u203c|\u2049|[\u25aa-\u25ab]|\u25b6|\u25c0|[\u25fb-\u25fe]|\u00a9|\u00ae|\u2122|\u2139|\ud83c\udc04|[\u2600-\u26FF]|\u2b05|\u2b06|\u2b07|\u2b1b|\u2b1c|\u2b50|\u2b55|\u231a|\u231b|\u2328|\u23cf|[\u23e9-\u23f3]|[\u23f8-\u23fa]|\ud83c\udccf|\u2934|\u2935|[\u2190-\u21ff])/g;
    
    if (str.match(regex)) {
	return str.replace(regex, '');
    }
    else return false;

}

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid 
// certificate authority.
app.listen(app.get('port'), function() {
  console.log('Node app is running on port', app.get('port'));
});

console.log("Hello World");

module.exports = app;
