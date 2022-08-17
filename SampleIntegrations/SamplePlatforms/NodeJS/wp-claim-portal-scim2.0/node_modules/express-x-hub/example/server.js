'use strict';

var express = require('express');
var xhub = require('../lib/middleware');

var app = express();

// XHub Middleware Install
app.use(xhub({ secret: 'my_little_secret' }));

// Xhub Handler -- Could Be Any Route.
app.post('/xhub', function(req, res){
    if(req.isXHub && req.isXHubValid()){
        return res.json({ success: 'X-Hub Is Valid' });
    }
    return res.status(400).json({ error: 'X-Hub Is Invalid' });
});

var server = app.listen(3000, function() {
  var host = server.address().address;
  var port = server.address().port;
  console.log('Example Express-X-Hub app listening at http://%s:%s', host, port);
});
