/* jshint node: true, devel: true */
'use strict';

const 
  bodyParser = require('body-parser'),
  config = require('config'),
  crypto = require('crypto'),
  express = require('express'),
  https = require('https'),
  moment = require('moment'),
  cron = require('node-schedule'),
  request = require('request'),
  githubhandles = require('./githubhandles.json');

console.log(githubhandles);

var app = express();
app.set('port', process.env.PORT || 5000);

app.use('/webhook/facebook',bodyParser.json({ verify: verifyRequestSignature }));
app.use('/webhook/github',bodyParser.urlencoded({ extended: true }));
app.use('/webhook/github',bodyParser.json());

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

// Generate a page access token for your page from the App Dashboard
const PAGE_ACCESS_TOKEN = (process.env.PAGE_ACCESS_TOKEN) ?
  (process.env.PAGE_ACCESS_TOKEN) :
  config.get('Workplace.pageAccessToken');

// URL where the app is running (include protocol). Used to point to scripts and 
// assets located at this address. 
const SERVER_URL = (process.env.SERVER_URL) ?
  (process.env.SERVER_URL) :
  config.get('Workplace.serverURL');

const GITHUB_TOKEN = (process.env.GITHUB_TOKEN) ?
  (process.env.GITHUB_TOKEN) :
  config.get('Github.token');

const GITHUB_REPO = (process.env.GITHUB_REPO) ?
  (process.env.GITHUB_REPO) :
  config.get('Github.repo');

if (!(APP_SECRET && VERIFY_TOKEN && PAGE_ACCESS_TOKEN && SERVER_URL && GITHUB_TOKEN && GITHUB_REPO )) {
  console.error("Missing config values");
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
    auth: {
        'bearer' : PAGE_ACCESS_TOKEN
    }
});

var githubapi = request.defaults({
    baseUrl: 'https://api.github.com',
    headers: {
        'User-Agent': 'GKFileAnIssue',
        'Content-Type': 'application/json'
    },
    auth: {
        'bearer' : GITHUB_TOKEN
    }
});

// Enable page subscriptions for this app, using the app-page token
function enableSubscriptions() {
  graphapi({
    method: 'POST',
    url: '/me/subscribed_apps'
  },function(error,response,body){
    // This should return with {success:true}, otherwise you've got problems!
    console.log('Enabling Subscriptions',body);
  });
}

// Subscrbe for message & mention updates
function subscribePageWebhook() {
  graphapi({
    method: 'POST',
    url: '/app/subscriptions',
    // Requires app token, not page token
    auth: {'bearer' : APP_TOKEN},
    qs: {
      'object': 'page',
      'fields': 'mention',
      'include_values': 'true',
      'verify_token': VERIFY_TOKEN,
      'callback_url': SERVER_URL + '/webhook/facebook'
    }
  },function(error,response,body){
    // This should return with {success:true}, otherwise you've got problems!
    console.log('Subscribing Page Webhook',body);
  });
}

function fbWebhookGet(req, res) {
  if (req.query['hub.mode'] === 'subscribe' &&
    // This verify token string should match whatever you used when you subscribed for the webhook
    req.query['hub.verify_token'] === VERIFY_TOKEN) {
    console.log("Validating webhook");
    res.status(200).send(req.query['hub.challenge']);
  } else {
    console.error("Failed validation. Make sure the validation tokens match.");
    res.sendStatus(403);
  }   
}

function fbWebhookPost(req, res) {
  //console.log(JSON.stringify(req.body, null, 2));
  if(req.body && req.body.entry) {
    for(var i in req.body.entry) {
      var changes = req.body.entry[i].changes;
      for(var j in changes) {
        // Changes field type = 'posts' for new posts
        if(changes[j].field && changes[j].field === 'mention') {
            if(changes[j].value && changes[j].value.item && changes[j].value.item == 'comment') {
                // comment
                var comment_id = changes[j].value.comment_id;
                var comment_message = changes[j].value.message;
                console.log('Mentioned in comment', comment_id, comment_message);
                
                // Get the content of the parent post
                var post_id = changes[j].value.post_id;
                graphapi({
                    url: '/' + post_id,
                    qs: { 'fields': 'message,permalink_url' }
                },function(error,response,body){
                    if(body) {
                        var post = JSON.parse(body);
                        likePostOrCommentId(comment_id);
                        createGithubIssue(comment_message, post.message, comment_id, post.permalink_url);
                    }
                });
            } else if(changes[j].value && changes[j].value.item && changes[j].value.item == 'post') {
                // post
                var postid = changes[j].value.post_id;
                console.log('Mentioned in post', postid);

                // Get the content of the post
                graphapi({
                    url: '/' + postid,
                    qs: { 'fields': 'message,from{name,email},formatting,permalink_url' }
                },function(error,response,body){
                    if(body) {
                        var post = JSON.parse(body);
                        likePostOrComment(post);
                        createGithubIssue('New Issue', post.message, post.id, post.permalink_url);
                    }
                });
            }
        } else {
            // Not a mention webhook, do something else here
            console.log('Not a mention webhook, do something else here');
        }
      }
    }
  } else {
    console.error('Webhook Callback',req.body);
  }
  // Always send back a 200 OK, otherwise Facebook will retry the callback later
  res.sendStatus(200);
}

var ghWebhookAll = function(req, res) {
    var payload = JSON.parse(req.body.payload);
    if(payload && payload.action && payload.action != 'opened') {
        var regex = /\[View on Workplace\]\(https:\/\/\w+.facebook.com\/groups\/\d+\/permalink\/(\d+)/i;
        var match = payload.issue.body.match(regex);
        console.log(payload);
        var message = 'Issue ' + payload.action + ' by @[' + githubhandles[payload.sender.login] + '].';
        if(match) {
            replyToPostOrCommentId(match[1], message);
        }
    }
    res.sendStatus(200);
}

// This will be called by Facebook when the webhook is being subscribed
app.get('/webhook/facebook', fbWebhookGet);

// Facebook webhook callbacks are done via POST
app.post('/webhook/facebook', fbWebhookPost);

// Catch all webhooks from GitHub
app.all('/webhook/github', ghWebhookAll);

var likePostOrCommentId = function(object_id) {
    console.log('Liking Post Or Comment',object_id);
    graphapi({
        method: 'POST',
        url: '/' + object_id + '/likes'
    },function(error,response,body){
        if(error) {
            console.error(error);
        }
    });
}

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

var createGithubIssue = function(title, description, origin_id, permalink_url) {
    console.log('Creating Github Issue',title, description, origin_id, permalink_url);
    githubapi({
        method: 'POST',
        url: '/' + GITHUB_REPO + '/issues',
        body: JSON.stringify({
            title: title,
            body: description + '\n\n[View on Workplace](' + permalink_url + ')'
        })
    },function(error,response,body){
        if(error) {
            console.error(error);
        } else {
            var issue = JSON.parse(body);
            replyToPostOrCommentId(origin_id,'Created issue: ' + issue.html_url);
        }
    });
}

enableSubscriptions();
subscribePageWebhook();

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid 
// certificate authority.
app.listen(app.get('port'), function() {
  console.log('Node app is running on port', app.get('port'));
});

module.exports = app;