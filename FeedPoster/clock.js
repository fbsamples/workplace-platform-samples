/*
 * Copyright 2017-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
var feed = require('feed-read');
var request = require('request');

var last_check = Date.now();

var postNewArticle = function() {
	console.log('Checking for new posts');
	feed(process.env.FEED_URL, function(err, articles) {
	  if (err) throw err;

	  for ( i in articles ) {
	  	// Only ever post one article per cycle
	  	if ( i > 0 ) return;
	  	
	  	var article = articles[i];
	  	// Only post articles published since last check
	  	if (article.published < last_check){
	  		console.log('No new posts since ' + last_check);
	  		return;
	  	}

	  	request({
	    	method: 'POST',
	    	url: 'https://graph.facebook.com/' + process.env.TARGET_GROUP + '/feed',
	    	qs: {
	    		'access_token': process.env.ACCESS_TOKEN,
	    		'message': article.title,
	    		'link': article.link
	    	}
	    },function(error,response,body){
	    	if(error){
	    		console.error(error);
	    	} else {
	    		var post_id = JSON.parse(body).id;
	    		console.log('Published "' + article.title + '": ' + post_id)
	    		last_check = Date.now();
	    	}
	    });
	  }
	});
}

//setInterval(postNewArticle, 1000)

var CronJob = require('cron').CronJob;
new CronJob({
  cronTime: process.env.CRON_PATTERN,
  onTick: postNewArticle,
  start: true,
  timeZone: "America/Los_Angeles"
});
console.log(process.env.CRON_PATTERN);