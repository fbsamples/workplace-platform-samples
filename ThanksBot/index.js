var express = require('express');
var bodyParser = require('body-parser');
var pg = require('pg');
pg.defaults.ssl = true;
var crypto = require('crypto');
var request = require('request');

var PAGE_ID = '';

var app = express();
app.set('port', (process.env.PORT || 5000));
app.use(express.static(__dirname + '/public'));
app.use(bodyParser.json({ verify: verifyRequestSignature }));
app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

app.get('/', function (request, response) {
  pg.connect(process.env.DATABASE_URL, function(err, client, done) {
    client.query('SELECT * FROM thanks', function(err, result) {
      done();
      if (err)
       { console.error(err); response.send("Error " + err); }
      else
       { response.render('pages/thanks', {results: result.rows} ); }
    });
  });
});

app.get('/webhook', function(request, response) {
  if (request.query['hub.mode'] === 'subscribe' &&
      request.query['hub.verify_token'] === process.env.VERIFY_TOKEN) {
    console.log("Validated webhook");
    response.status(200).send(request.query['hub.challenge']);
  } else {
    console.error("Failed validation. Make sure the validation tokens match.");
    response.sendStatus(403);          
  } 
});

app.post('/webhook', function(request, response) {
	var data = request.body;
	if(request.body && request.body.entry) {
		for(var i in request.body.entry) {
			var changes = request.body.entry[i].changes;
			for(var j in changes) {
				if(changes[j].field && changes[j].field === 'mention') {
					var mention_id = '';
					if(changes[j].value && changes[j].value.item && changes[j].value.item == 'comment') {
						mention_id = changes[j].value.comment_id;
					} else if(changes[j].value && changes[j].value.item && changes[j].value.item == 'post') {
						mention_id = changes[j].value.post_id;
					}

					// Like first
					graphapi({
						url: '/' + mention_id + '/likes',
						method: 'POST'
					}, function(error,res,body) {
						console.log('Like', mention_id, body);
					});

					// Get mention text from Graph API
					// /id?fields=message,message_tags,permalink_url
					graphapi({
						url: '/' + mention_id,
						qs: {
							fields: 'from,message,message_tags,permalink_url'
						}
					},function(error,res,body){
						if(body) {
							body = JSON.parse(body);
							var query = 'INSERT INTO thanks VALUES ';
							var inserts = 0;
							for(var t in body.message_tags) {
								if(body.message_tags[t].type == 'page') continue;
								//add a comma after every insert value group
								if(inserts++ != 0) query += ',';
								query += 
									'(now(),' 
									+ '\'' + body.permalink_url + '\','
									+ '\'' + body.message_tags[t].id + '\','
									+ '\'\'' + ',' // TODO: Add manager
									+ '\'' + body.from.id + '\','
									+ '\'' + body.message + '\')';
							}
							var interval = '1 week';
							query += '; SELECT * FROM thanks WHERE create_date > now() - INTERVAL \''+interval+'\';';
							pg.connect(process.env.DATABASE_URL, function(err, client, done) {
								client.query(query, function(err, result) {
									done();
									if (err) { 
										console.error(err); 
									} else if (result) {
										var summary = 'Thanks received!\n'

										// iterate through result rows, count number of thanks sent
										var sender_thanks_sent = 0;
										for(var r in result.rows){
											if(result.rows[r].sender == body.from.id) sender_thanks_sent++;
										}
										summary += '@[' + body.from.id + '] has sent '+sender_thanks_sent+' thanks in the last ' + interval + '.\n';

										for(var t in body.message_tags) {
											// Ignore page mentions
											if(body.message_tags[t].type == 'page') continue;

											// iterate through result rows, count number of thanks received
											var recipient_received = 0;
											for(var r in result.rows){
												if(result.rows[r].recipient == body.message_tags[t].id) recipient_received++;
											}
											summary += '@[' + body.message_tags[t].id + '] has received '+recipient_received+' thanks in the last ' + interval + '.\n';
										}
										// Comment reply
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
						}
					});
				}
			}
		}
	}
});

app.listen(app.get('port'), function() {
  console.log('Node app is running on port', app.get('port'));
});

var graphapi = request.defaults({
    baseUrl: 'https://graph.facebook.com',
    auth: {
        'bearer' : process.env.ACCESS_TOKEN
    }
});

function getPageID() {
	graphapi({
		url: '/me'
	},function(error,response,body){
		PAGE_ID = body.id;
	});
}

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

    var expectedHash = crypto.createHmac('sha1', process.env.APP_SECRET)
                        .update(buf)
                        .digest('hex');

    if (signatureHash != expectedHash) {
      throw new Error("Couldn't validate the request signature.");
    }
  }
}