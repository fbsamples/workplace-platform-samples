/*  eslint no-unused-expressions:0  */

'use strict';

var error = require('../lib/error');

describe('xhub.error', function(){

    it('should return an Error Object', function(){
        var err = error();
        err.should.be.an.instanceof(Error);
    });

    it('should return the correct status code', function(){
        var code = 400;
        var err = error(code);
        err.status.should.equal(code);
    });

    it('should return the message when sent', function(){
        var message = 'specific_error_message';
        var err = error(null, message);
        err.message.should.equal(message);
    });

    it('should use a standard http message when message is empty', function(){
        var code = 400;
        var http = require('http');
        var message = http.STATUS_CODES[code];
        var err = error(code);
        err.message.should.equal(message);
    });

});
