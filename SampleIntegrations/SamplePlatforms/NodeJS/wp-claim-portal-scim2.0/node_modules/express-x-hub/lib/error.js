'use strict';

var http = require('http');

module.exports = function(code, msg){
    var err = new Error(msg || http.STATUS_CODES[code]);
    err.status = code;
    return err;
};
