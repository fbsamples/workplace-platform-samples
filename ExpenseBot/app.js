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

var claims = [];
var conversation_state = [];

/*
 * Be sure to setup your config values before running this code. You can
 * set them using environment variables or modifying the config file in /config.
 *
 */
const ACCESS_TOKEN = process.env.ACCESS_TOKEN,
    APP_ID = process.env.APP_ID,
    APP_SECRET = process.env.APP_SECRET,
    VERIFY_TOKEN = process.env.VERIFY_TOKEN,
    SERVER_URL = process.env.SERVER_URL;

if (!(APP_ID && APP_SECRET && VERIFY_TOKEN && ACCESS_TOKEN && SERVER_URL)) {
    console.error('Missing config values');
    process.exit(1);
}

var graphapi = request.defaults({
    baseUrl: 'https://graph.facebook.com/v2.9',
    json: true,
    auth: {
        'bearer' : ACCESS_TOKEN
    }
});

// Enable page subscriptions for this app, using the app-page token
function enableSubscriptions() {
    graphapi({
        url: '/me/subscribed_apps',
        method: 'POST'
    },function(error,response,body) {
    // This should return with {success:true}, otherwise you've got problems!
        console.log('enableSubscriptions',body);
    });
}

function subscribeWebhook() {
    graphapi({
        url: '/app/subscriptions',
        method: 'POST',
        auth: {'bearer' : APP_ID + '|' + APP_SECRET},
        qs: {
            'object': 'page',
            'fields': 'message_deliveries,messages,messaging_postbacks,messaging_optins',
            'verify_token': VERIFY_TOKEN,
            'callback_url': SERVER_URL + '/webhook'
        }
    }, function (error, response) {
        if(error) {
            console.error(error);
        } else {
            console.log('subscribeWebhook',response.body);
        }
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
    var signature = req.headers['x-hub-signature'];

    if (!signature) {
    // For testing, let's log an error. In production, you should throw an
    // error.
        console.error('Couldn\'t validate the signature.');
    } else {
        var elements = signature.split('=');
        var signatureHash = elements[1];

        var expectedHash = crypto.createHmac('sha1', APP_SECRET)
                        .update(buf)
                        .digest('hex');

        if (signatureHash != expectedHash) {
            throw new Error('Couldn\'t validate the request signature.');
        }
    }
}

function generateNewId() {
    var id = '';
    var possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    for(var i=0; i < 5; i++ ) {
        id += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return id;
}

function getUnsubmittedClaims(submitter) {
  // TODO: Sort by date_updated, date_created
    var openClaims = [];
    for(var i in claims) {
        if( claims[i].submitter == submitter ) {
            if( claims[i].status == 'unsubmitted' ) {
                openClaims.push(claims[i]);
            }
        }
    }
    return openClaims;
}

function getActiveClaim(submitter) {
    for(var i in claims) {
        if( claims[i].submitter == submitter ) {
            if( claims[i].status == 'new' ) {
                return claims[i];
            }
        }
    }
}

function getClaim(id) {
    for(var i in claims) {
        if( claims[i].id == id ) {
            return claims[i];
        }
    }
    return null;
}

function removeClaim(id) {
    for(var i in claims) {
        if( claims[i].id == id ) {
            claims.splice(i, 1);
        }
    }
    return null;
}

function addNewClaim(submitter,amount,comment,receipt,status) {
  // TODO: Add date_created, date_updated
    var claim = {
        'id': generateNewId(),
        'submitter': submitter,
        'amount': amount,
        'comment': comment,
        'receipt': receipt,
        'status': status
    };
    claims.push(claim);
    return claim;
}

function updateClaim(id,amount,comment,receipt,status) {
    var claim = getClaim(id);
    if(!claim) return null;
    claim.amount = amount;
    claim.comment = comment;
    claim.receipt = receipt;
    claim.status = status;
    return claim;
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
                    receivedMessage(messagingEvent);
                } else if (messagingEvent.postback) {
                    receivedPostback(messagingEvent);
                } else {
                    console.log('Webhook received unknown messagingEvent: ', messagingEvent);
                }
            });
        });

        // Assume all went well.
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
    var message = event.message;

    if (message.quick_reply) {
        var tokens = message.quick_reply.payload.split(':');
        var action = tokens[0];
        var object = tokens[1];

        switch (action) {
        case 'FILE_NEW_CLAIM':
            clearConversationState(senderID);
            startFileNewClaim(senderID);
            break;
        case 'VIEW_OPEN_CLAIMS':
            sendOpenClaims(senderID);
            break;
        default:
            console.log('Quick reply tapped', senderID, action);
            break;
        }
    } else {
        if(conversation_state[senderID]) {
            switch (conversation_state[senderID]) {
            case 'EXPECTING_RECEIPT':
                handleReceiptMessage(senderID, message);
                break;
            case 'EXPECTING_AMOUNT':
                handleAmountMessage(senderID, message);
                break;
            case 'EXPECTING_COMMENT':
                handleCommentMessage(senderID, message);
                break;
            default:
                sendGetStarted(senderID);
                break;
            }
        }
        return;
    }
}

function startFileNewClaim(senderID) {
    addNewClaim(senderID,null,null,null,'new');
    sendAskForReceipt(senderID);
}

function sendAskForReceipt(senderID) {
    setConversationState(senderID, 'EXPECTING_RECEIPT');
    sendTextMessage(senderID, 'Send a picture of the receipt');
}

function handleReceiptMessage(senderID, message) {
    var claim = getActiveClaim(senderID);
    if(claim
    && message.attachments
    && message.attachments[0]
    && message.attachments[0].type == 'image') {
        claim.receipt = message.attachments[0].payload.url;
        sendAskForAmount(senderID);
    } else {
        sendGetStarted(senderID);
    }
}

function sendAskForAmount(senderID) {
    setConversationState(senderID, 'EXPECTING_AMOUNT');
    sendTextMessage(senderID, 'How much is the receipt for?');
}

function handleAmountMessage(senderID, message) {
    var claim = getActiveClaim(senderID);
    var currencyRegex = /^[$£€]\d+(?:\.\d\d)*$/g;
    if(claim && message.text && message.text.match(currencyRegex)) {
        claim.amount = message.text;
        sendAskForComment(senderID);
    } else {
        sendAskForAmount(senderID);
    }
}

function sendAskForComment(senderID) {
    setConversationState(senderID, 'EXPECTING_COMMENT');
    sendTextMessage(senderID, 'Add a comment to your claim');
}

function handleCommentMessage(senderID, message) {
    var claim = getActiveClaim(senderID);
    if(claim && message.text) {
        claim.comment = message.text;
        claim.status = 'unsubmitted';
    // We're all done, so remove the conversation state
        clearConversationState(senderID);
        sendOpenClaims(senderID);
    }
}

function setConversationState(senderID, state) {
    conversation_state[senderID] = state;
}

function clearConversationState(senderID) {
    conversation_state[senderID] = null;
}

/*
 * Postback Event
 *
 * This event is called when a postback is tapped on a Structured Message.
 * https://developers.facebook.com/docs/messenger-platform/webhook-reference/postback-received
 *
 */
function receivedPostback(event) {
    var senderID = event.sender.id;

  // The 'payload' param is a developer-defined field which is set in a postback
  // button for Structured Messages.
    var payload = event.postback.payload;
  // Embed extra info int he payload in the format ACTION:OBJECT
    var tokens = payload.split(':');
    var action = tokens[0];
    var object = tokens[1];

  // When a postback is called, we'll send a message back to the sender to
  // let them know it was successful
    switch (action) {
    case 'DELETE_CLAIM':
        removeClaim(object);
        sendOpenClaims(senderID);
        break;
    case 'GET_STARTED_PAYLOAD':
        sendGetStarted(senderID);
        break;
    case 'VIEW_OPEN_CLAIMS':
        sendOpenClaims(senderID);
        break;
    case 'FILE_NEW_CLAIM':
        startFileNewClaim(senderID);
        break;
    case 'SUBMIT_CLAIM':
        submitClaim(senderID,object);
        break;
    case 'APPROVE_CLAIM':
        approveClaim(senderID,object);
        break;
    case 'REJECT_CLAIM':
        rejectClaim(senderID,object);
        break;
    default:
        sendTextMessage(senderID, 'Postback called: ' + payload);
        break;
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
            metadata: 'DEVELOPER_DEFINED_METADATA'
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
    graphapi({
        url: '/me/messages',
        method: 'POST',
        json: messageData
    }, function (error, response, body) {
        if (!error && response.statusCode == 200) {
            var recipientId = body.recipient_id;
            var messageId = body.message_id;

            if (messageId) {
                console.log('Successfully sent message with id %s to recipient %s',
          messageId, recipientId);
            } else {
                console.log('Successfully called Send API for recipient %s',
        recipientId);
            }
        } else {
            console.error('Failed calling Send API', response.statusCode, response.statusMessage, body.error);
        }
    });
}

function setupPersistentMenu() {
    graphapi({
        url: '/me/messenger_profile',
        method: 'POST',
        qs: {
            'persistent_menu':[
                {
                    'locale':'default',
                    'composer_input_disabled':false,
                    'call_to_actions':[
                        {
                            'title':'File a new claim',
                            'type':'postback',
                            'payload':'FILE_NEW_CLAIM'
                        },
                        {
                            'title':'View open claims',
                            'type':'postback',
                            'payload':'VIEW_OPEN_CLAIMS'
                        }
                    ]
                }
            ]
        },
    }, function (error, response) {
        if(error) {
            console.error(error);
        } else {
            console.log('setupPersistentMenu',response.body);
        }
    });
}

function setupGetStartedButton() {
    graphapi({
        url: '/me/thread_settings',
        method: 'POST',
        qs: {
            'setting_type':'call_to_actions',
            'thread_state':'new_thread',
            'call_to_actions':[
                {
                    'payload':'GET_STARTED_PAYLOAD'
                }
            ]
        },
    }, function (error, response) {
        if(error) {
            console.error(error);
        } else {
            console.log('setupGetStartedButton',response.body);
        }
    });
}

function setupGreetingText() {
    graphapi({
        url: '/me/messenger_profile',
        method: 'POST',
        qs: {
            'greeting':[
                {
                    'locale':'default',
                    'text':'Hello! I\'m Expense Bot.'
                }, {
                    'locale':'en_US',
                    'text':'Howdy! I\'m Expense Bot.'
                }
            ]
        },
    }, function (error, response) {
        if(error) {
            console.error(error);
        } else {
            console.log('setupGreetingText',response.body);
        }
    });
}

function sendGetStarted(recipientId) {
    graphapi({
        url: '/' + recipientId,
        qs: {
            'fields': 'first_name'
        }
    },function(error,response,body) {
        body = JSON.parse(body);
        var messageData = {
            recipient: {
                id: body.id
            },
            message: {
                text: 'Hi ' + body.first_name + ', what would you like to do?',
                quick_replies: [
                    {
                        'content_type':'text',
                        'title':'New Claim',
                        'payload':'FILE_NEW_CLAIM'
                    },
                    {
                        'content_type':'text',
                        'title':'View Claims',
                        'payload':'VIEW_OPEN_CLAIMS'
                    }
                ]
            }
        };
        callSendAPI(messageData);
    });
}

function claimToElement(claim, viewerId) {

    var subtitle = 'Amount: ' + claim.amount +
    '\nStatus: ' + claim.status;
    if(claim.submitterName)
        subtitle += '\nSender: ' + claim.submitterName;
    if(claim.approverName)
        subtitle += '\nApprover: ' + claim.approverName;

    var element = {
        title: claim.comment,
        subtitle: subtitle,
        image_url: claim.receipt
    };
    var buttons = [];
    if(claim.status == 'unapproved' && claim.approver == viewerId) {
        buttons.push({
            type: 'postback',
            title: '✔︎ Approve',
            payload: 'APPROVE_CLAIM:' + claim.id
        });
        buttons.push({
            type: 'postback',
            title: '✘ Reject',
            payload: 'REJECT_CLAIM:' + claim.id
        });
    }
    if(claim.status == 'unsubmitted' && claim.submitter == viewerId) {
        buttons.push({
            type: 'postback',
            title: '✔︎ Submit',
            payload: 'SUBMIT_CLAIM:' + claim.id
        });
        buttons.push({
            type: 'postback',
            title: '✎ Edit',
            payload: 'EDIT_CLAIM:' + claim.id
        });
        buttons.push({
            type: 'postback',
            title: '✘ Delete',
            payload: 'DELETE_CLAIM:' + claim.id
        });
    }
    if( buttons.length > 0 ) element.buttons = buttons;
    return element;
}

function sendClaim(recipientId, claimId) {
    var claim = getClaim(claimId);

    var element = claimToElement(claim, recipientId);
    var messageData = {
        recipient: {
            id: recipientId
        },
        message: {
            attachment: {
                type: 'template',
                payload: {
                    template_type: 'generic',
                    image_aspect_ratio: 'square',
                    elements: [element]
                }
            }
        }
    };
    callSendAPI(messageData);
}

function sendOpenClaims(recipientId) {
  // Get open claims from the expense platform
    var open_claims = getUnsubmittedClaims(recipientId);

    if( open_claims.length == 0 ) {
        sendTextMessage(recipientId, 'No open claims');
    } else {
        var elements = [];
        for(var i in open_claims) {
            elements.push(claimToElement(open_claims[i], recipientId));
        }
        var messageData = {
            recipient: {
                id: recipientId
            },
            message: {
                attachment: {
                    type: 'template',
                    payload: {
                        template_type: 'generic',
                        image_aspect_ratio: 'square',
                        elements: elements
                    }
                }
            }
        };

        callSendAPI(messageData);
    }
}

function submitClaim(senderID, claimId) {
    graphapi({
        url: '/' + senderID,
        qs: {
            fields: 'name,managers{name}'
        }
    },function(error,response,body) {
        body = JSON.parse(body);
        if(body.managers && body.managers.data[0]) {
            var manager = body.managers.data[0];
            var claim = getClaim(claimId);
            claim.submitterName = body.name;
            claim.approver = manager.id;
            claim.approverName = manager.name;
            claim.status = 'unapproved';
            sendTextMessage(manager.id, 'New claim to approve');
            sendClaim(manager.id, claimId);
        }
    });
}

function approveClaim(senderID, claimId) {
    var claim = getClaim(claimId);
    claim.status = 'approved';
    sendTextMessage(claim.submitter, 'Claim approved by ' + claim.approverName);
    sendClaim(claim.submitter, claimId);
}

function rejectClaim(senderID, claimId) {
    var claim = getClaim(claimId);
    claim.status = 'rejected';
    sendTextMessage(claim.submitter, 'Claim rejected by ' + claim.approverName);
    sendClaim(claim.submitter, claimId);
}

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid
// certificate authority.
app.listen(app.get('port'), function() {
    console.log('Node app is running on port', app.get('port'));
    enableSubscriptions();
    subscribeWebhook();
    setupGetStartedButton();
    setupPersistentMenu();
    setupGreetingText();
});

module.exports = app;
