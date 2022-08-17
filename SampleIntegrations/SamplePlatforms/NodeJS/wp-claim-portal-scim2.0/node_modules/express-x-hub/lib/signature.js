'use strict';

var crypto = require('crypto');

var Signature = function(xhub, options){
    this.xhub = xhub;
    options = options || {};
    this.algorithm = options.algorithm || 'sha1';
    this.secret = options.secret;
};

Signature.prototype.attach = function(req, buffer){
    var isValid = this.isValid.bind(this);
    req.isXHubValid = function(){
        return isValid(buffer);
    };
};

Signature.prototype.isValid = function(buffer){
    if(!this.secret) { throw new Error('No Secret Found'); }
    var hmac = crypto.createHmac(this.algorithm, this.secret);
    hmac.update(buffer, 'utf-8');
    var expected = this.algorithm + '=' + hmac.digest('hex');
    return this.xhub === expected;
};

module.exports = Signature;
