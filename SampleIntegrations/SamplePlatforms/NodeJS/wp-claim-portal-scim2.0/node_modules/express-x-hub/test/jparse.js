/*  eslint no-unused-expressions:0  */

'use strict';

var jparse = require('../lib/jparse');

describe('xhub.jparse', function(){

    it('should throw when buffer is undefined', function(){
        (jparse).should.throw(Error);
    });

    it('should throw when buffer is an empty string', function(){
        (function(){ jparse(''); }).should.throw(Error);
    });

    it('should throw when buffer is a string with only whitespace', function(){
        (function(){ jparse('   '); }).should.throw(Error);
    });

    it('should throw when strict option is true and json is not strict', function(){
        var options = { strict: true };
        var unstrictJson = '"hello": "world" ';
        (function(){ jparse(unstrictJson, options); }).should.throw(Error);
    });

    it('should throw when json is invalid', function(){
        var invalidJson = ' { "hello": world } ';
        (function(){ jparse(invalidJson); }).should.throw(Error);
    });

    it('should correctly parse valid json', function(){
        var validJson = ' { "hello": "world"  }';
        var json = jparse(validJson);
        json.hello.should.equal('world');
    });

});
