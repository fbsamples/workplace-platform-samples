/*
 * Copyright 2017-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

const 
	crypto = require('crypto'),
	express = require('express'),
	bodyParser = require('body-parser'),
	pg = require('pg'),
	request = require('request');

const
	VERIFY_TOKEN = process.env.VERIFY_TOKEN,
	ACCESS_TOKEN = process.env.ACCESS_TOKEN,
	APP_SECRET = process.env.APP_SECRET,
	DATABASE_URL = process.env.DATABASE_URL;

if (!(APP_SECRET && VERIFY_TOKEN && ACCESS_TOKEN && DATABASE_URL)) {
	console.error('Missing environment values.');
	process.exit(1);
}

pg.defaults.ssl = true;

var app = express();
app.set('port', (process.env.PORT || 5000));
app.use(express.static(__dirname + '/public'));
app.use(bodyParser.json({ verify: verifyRequestSignature }));
app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

// List out all the thanks recorded in the database
app.get('/', function (request, response) {
	pg.connect(DATABASE_URL, function(err, client, done) {
		client.query('SELECT * FROM thanks', function(err, result) {
			done();
			if (err) { 
				console.error(err); response.send('Error ' + err);
			} else {
				response.render('pages/thanks', {results: result.rows} ); 
			}
		});
	});
});

// Handle the webhook subscription request from Facebook
app.get('/webhook', function(request, response) {
	if (request.query['hub.mode'] === 'subscribe' &&
		request.query['hub.verify_token'] === VERIFY_TOKEN) {
		console.log('Validated webhook');
		response.status(200).send(request.query['hub.challenge']);
	} else {
		console.error('Failed validation. Make sure the validation tokens match.');
		response.sendStatus(403);          
	}
});

// Handle webhook payloads from Facebook
app.post('/webhook', function(request, response) {
	if(request.body && request.body.entry) {
		request.body.entry.forEach(function(entry){
			entry.changes.forEach(function(change){
				if(change.field === 'mention') {
					let mention_id = (change.value.item === 'comment') ? 
						change.value.comment_id : change.value.post_id;
					// Like the post or comment to indicate acknowledgement
					graphapi({
						url: '/' + mention_id + '/likes',
						method: 'POST'
					}, function(error,res,body) {
						console.log('Like', mention_id, body);
					});
					// Get mention text from Graph API
					graphapi({
						url: '/' + mention_id,
						qs: {
							fields: 'from,message,message_tags,permalink_url'
						}
					}, function(error,res,body){
						if(body) {
							let message = body.message,
								sender = body.from.id,
								permalink_url = body.permalink_url,
								recipients = [],
								managers = [],
								query_inserts = [];

							body.message_tags.forEach(function(message_tag){
								// Ignore page / group mentions
								if(message_tag.type !== 'user') return;
								// Add the recipient to a list, for later retrieving their manager
								recipients.push(message_tag.id);
							});
							// Get recipients' managers in bulk using the ?ids= batch fetching method
							graphapi({
								url: '/',
								qs: {
									ids: recipients.join(','),
									fields: 'managers'
								}
							}, function(error,res,body){
								// Add a data row for the insert query
								console.log('Managers', body);
								recipients.forEach(function(recipient){
									// Check if we found their manager
									let manager = '';
									if(body 
										&& body[recipient] 
										&& body[recipient].managers 
										&& body[recipient].managers.data[0]) 
										manager = body[recipient].managers.data[0].id;
									managers[recipient] = manager;
									query_inserts.push(`(now(),'${permalink_url}','${recipient}','${manager}','${sender}','${message}')`);
								});
								var interval = '1 week';
								let query = 'INSERT INTO thanks VALUES ' 
									+ query_inserts.join(',')
									+ `; SELECT * FROM thanks WHERE create_date > now() - INTERVAL '${interval}';`;
								console.log('Query', query);
								pg.connect(DATABASE_URL, function(err, client, done) {
									client.query(query, function(err, result) {
										done();
										if (err) { 
											console.error(err); 
										} else if (result) {
											var summary = 'Thanks received!\n';
											// iterate through result rows, count number of thanks sent
											var sender_thanks_sent = 0;
											result.rows.forEach(function(row){
												if(row.sender == sender) sender_thanks_sent++;
											});
											summary += `@[${sender}] has sent ${sender_thanks_sent} thanks in the last ${interval}\n`;

											// Iterate through recipients, count number of thanks received
											recipients.forEach(function(recipient){
												let recipient_thanks_received = 0;
												result.rows.forEach(function(row){
													if(row.recipient == recipient) recipient_thanks_received++;
												});
												if(managers[recipient]) {
													summary += `@[${recipient}] has received ${recipient_thanks_received} thanks in the last ${interval}. Heads up to @[${managers[recipient]}].\n`;
												} else {
													summary += `@[${recipient}] has received ${recipient_thanks_received} thanks in the last ${interval}. I don't know their manager.\n`;
												}
											});
											// Comment reply with thanks stat summary
											graphapi({
												url: '/' + mention_id + '/comments',
												method: 'POST',
												qs: {
													message: summary
												}
											}, function(error,res,body) {
												console.log('Comment reply', mention_id, body);
											});
										}
										response.sendStatus(200);
									});
								});
							});
						}
					});
				}
			});
		});
	}
});

app.listen(app.get('port'), function() {
	console.log('Node app is running on port', app.get('port'));
});

var graphapi = request.defaults({
	baseUrl: 'https://graph.facebook.com',
	json: true,
	auth: {
		'bearer' : ACCESS_TOKEN
	}
});

function verifyRequestSignature(req, res, buf) {
	var signature = req.headers['x-hub-signature'];

	if (!signature) {
		// For testing, let's log an error. In production, you should throw an error.
		console.error("Couldn't validate the signature.");
	} else {
		var elements = signature.split('=');
		var signatureHash = elements[1];

		var expectedHash = crypto.createHmac('sha1', APP_SECRET)
			.update(buf)
			.digest('hex');

		if (signatureHash != expectedHash) {
			throw new Error("Couldn't validate the request signature.");
		}
	}
}