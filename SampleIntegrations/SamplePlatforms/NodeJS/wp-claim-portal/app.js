var express = require('express'),
    config = require('./config/config');

var app = express();

require('./config/express')(app, config);

app.listen(config.port || 9000, function () {
    console.log('Express server started and listening on ' + this.address().port + ".");
});
