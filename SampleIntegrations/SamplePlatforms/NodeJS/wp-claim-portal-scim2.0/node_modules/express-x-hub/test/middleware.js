/*  eslint no-unused-expressions:0  */

'use strict';

var middleware = require('../lib/middleware');
var Readable = require('stream').Readable;

var createRequest = function(signature, type, body, length){
    var req = new Readable();
    req.headers = {
        'content-type': type || 'application/json',
        'transfer-encoding': 'chunked',
        'X-Hub-Signature': signature,
        'content-length': length || (body ? body.length : 0)
    };
    req.header = function(name){
        return this.headers[name];
    };
    req._read = function(){
        this.push(body);
        this.push(null);
    };
    return req;
};

describe('xhub.middleware', function(){

    it('should set isXHub to false when the request is not json', function(done){
        var req = createRequest(null, 'application/xml');
        var middle = middleware();
        middle(req, null, function(){
            req.isXHub.should.be.false;
            done();
        });
    });

    it('should set isXHub to false is express has already flagged as parsed', function(done){
        var req = createRequest();
        req._body = true;
        var middle = middleware();
        middle(req, null, function(){
            req.isXHub.should.be.false;
            done();
        });
    });

    it('should set isXHub to false when the xhub header is not in the request', function(done){
        var req = createRequest();
        var middle = middleware();
        middle(req, null, function(){
            req.isXHub.should.be.false;
            done();
        });
    });

    it('should set express parsed flag when request is xhub', function(done){
        var req = createRequest('signature');
        var middle = middleware();
        middle(req, null, function(){
            req._body.should.be.true;
            done();
        });
    });

    it('should set error when raw body is larger than the limit', function(done){
        var limit = 1;
        var body = 'longer_than_the_limit';
        var req = createRequest('signature', null, body, limit);
        var middle = middleware();
        middle(req, null, function(err){
            err.should.exist;
            done();
        });
    });

    it('should set attach xhub when the request is valid', function(done){
        var body = 'body';
        var req = createRequest('signature', null, body);
        var middle = middleware();
        middle(req, null, function(){
            req.isXHubValid.should.exist;
            done();
        });
    });

    it('should parse valid json into the request body', function(done){
        var body = '{ "hello": "world" }';
        var req = createRequest('signature', null, body);
        var middle = middleware();
        middle(req, null, function(){
            req.body.hello.should.equal('world');
            done();
        });
    });

    it('should error when parse invalid json', function(done){
        var body = '{ invalid }';
        var req = createRequest('signature', null, body);
        var middle = middleware();
        middle(req, null, function(err){
            err.should.exist;
            done();
        });
    });

    it('should set the error status when parse invalid json', function(done){
        var body = '{ invalid }';
        var req = createRequest('signature', null, body);
        var middle = middleware();
        middle(req, null, function(err){
            err.status.should.equal(400);
            done();
        });
    });

    // End-To-End Tests

    it('should not return an error when the request is correct', function(done){
        var body = '{ "id": "realtime_update" }';
        var xhubSignature = 'sha1=c1a072c0aca15c6bd2f5bfae288ff8420e74aa5e';
        var req = createRequest(xhubSignature, null, body);
        var middle = middleware({
            algorithm: 'sha1',
            secret: 'my_little_secret'
        });
        middle(req, null, function(err){
            global.should.not.exist(err);
            done();
        });
    });

    it('should set isXHub to true when the request is x-hub', function(done){
        var body = '{ "id": "realtime_update" }';
        var xhubSignature = 'sha1=c1a072c0aca15c6bd2f5bfae288ff8420e74aa5e';
        var req = createRequest(xhubSignature, null, body);
        var middle = middleware({
            algorithm: 'sha1',
            secret: 'my_little_secret'
        });
        middle(req, null, function(){
            req.isXHub.should.be.true;
            done();
        });
    });

    it('should set isXHub to false when the request is not x-hub', function(done){
        var body = '{ "id": "realtime_update" }';
        var xhubSignature = null;
        var req = createRequest(xhubSignature, null, body);
        var middle = middleware({
            algorithm: 'sha1',
            secret: 'my_little_secret'
        });
        middle(req, null, function(){
            req.isXHub.should.be.false;
            done();
        });
    });

    it('should set isXHubValid to true when the request signature is valid ', function(done){
        var body = '{ "id": "realtime_update" }';
        var xhubSignature = 'sha1=c1a072c0aca15c6bd2f5bfae288ff8420e74aa5e';
        var req = createRequest(xhubSignature, null, body);
        var middle = middleware({
            algorithm: 'sha1',
            secret: 'my_little_secret'
        });
        middle(req, null, function(){
            req.isXHubValid().should.be.true;
            done();
        });
    });

    it('should set isXHubValid to false when the request signature is invalid ', function(done){
        var body = '{ "id": "realtime_update" }';
        var xhubSignature = 'sha1=invalid_req_signature';
        var req = createRequest(xhubSignature, null, body);
        var middle = middleware({
            algorithm: 'sha1',
            secret: 'my_little_secret'
        });
        middle(req, null, function(){
            req.isXHubValid().should.be.false;
            done();
        });
    });

});
