/*
 * Copyright 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

/* jshint node: true, devel: true */
"use strict";

const 
	bodyParser = require("body-parser"),
	crypto = require("crypto"),
	express = require("express");
require("dotenv").load();

var app = express();
app.set("port", process.env.PORT || 5000);
app.use(bodyParser.json({ verify: verifyRequestSignature }));

/*
 * Be sure to setup your config values before running this code. You can 
 * set them using environment variables or modifying the config file in /config.
 *
 * App Secret can be retrieved from the App Dashboard
 * Any arbitrary value used to validate a webhook
 * Generate a page access token for your page from the App Dashboard
 *
 */
// 
const 
	APP_SECRET = process.env.APP_SECRET,
	VERIFY_TOKEN = process.env.VERIFY_TOKEN,
	ACCESS_TOKEN = process.env.ACCESS_TOKEN;

if (!(APP_SECRET && VERIFY_TOKEN && ACCESS_TOKEN)) {
	console.error("Missing config values");
	process.exit(1);
}

/*
 * Use your own validation token. Check that the token used in the Webhook 
 * setup is the same token used here.
 *
 */
app.get("/", function(req, res) {
	if (req.query["hub.mode"] === "subscribe" &&
      req.query["hub.verify_token"] === VERIFY_TOKEN) {
		console.log("Validating webhook");
		res.status(200).send(req.query["hub.challenge"]);
	} else {
		console.error("Failed validation. Make sure the validation tokens match.");
		res.sendStatus(403);          
	}  
});


/*
 * All callbacks for webhooks are POST-ed. They will be sent to the same
 * webhook. Be sure to subscribe your app to your page to receive callbacks.
 *
 */
app.post("/", function (req, res) {
	try{
		var data = req.body;
    // On Workplace, webhooks can be sent for page, group and workplace_security objects
		switch (data.object) {
		case "page":
			processPageEvents(data);
			break;
		case "group":
			processGroupEvents(data);
			break;
		case "workplace_security":
			processWorkplaceSecurityEvents(data);
			break;
		default:
			console.log("Unhandled Webhook Object", data.object);
		}
	} catch (e) {
    // Write out any exceptions for now
		console.error(e);
	} finally {
    // Always respond with a 200 OK for handled webhooks, to avoid retries from Facebook
		res.sendStatus(200);
	}
});

function processPageEvents(data) {
	data.entry.forEach(function(entry){
		let page_id = entry.id;
		entry.messaging.forEach(function(messaging_event){
			console.log("Page Messaging Event",page_id,messaging_event);
		});
	});
}

function processGroupEvents(data) {
	data.entry.forEach(function(entry){
		let group_id = entry.id;
		entry.changes.forEach(function(change){
			console.log("Group Change",group_id,change);
		});
	});
}

function processWorkplaceSecurityEvents(data) {
	data.entry.forEach(function(entry){
		let group_id = entry.id;
		entry.changes.forEach(function(change){
			console.log("Workplace Security Change",group_id,change);
		});
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
		var elements = signature.split("=");
		var signatureHash = elements[1];

		var expectedHash = crypto.createHmac("sha1", APP_SECRET)
                        .update(buf)
                        .digest("hex");

		if (signatureHash != expectedHash) {
			throw new Error("Couldn't validate the request signature.");
		}
	}
}

// Start server
// Webhooks must be available via SSL with a certificate signed by a valid 
// certificate authority.
app.listen(app.get("port"), function() {
	console.log("Node app is running on port", app.get("port"));
});

module.exports = app;