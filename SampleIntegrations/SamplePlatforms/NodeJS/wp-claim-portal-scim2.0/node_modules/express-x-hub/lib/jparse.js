'use strict';

var error = require('./error');

var EMPTY_MESSAGE = 'Invalid JSON, Empty Message Body';
var ERROR_CODE = 400;

// ExpressJS-Style JSON Parse
module.exports = function(buffer, options){
    options = options || {};
    if(!buffer){ throw error(ERROR_CODE, EMPTY_MESSAGE); }
    var first = buffer.trim()[0];
    if (buffer.length === 0){ throw error(ERROR_CODE, EMPTY_MESSAGE); }
    if (options.strict && first !== '{' && first !== '['){
        throw error(ERROR_CODE, 'Unable To Parse JSON In Strict Mode');
    }
    try { return JSON.parse(buffer, options.reviver); }
    catch(e) {
        var invalidJson = 'Unable To Parse JSON. ' + e;
        throw error(ERROR_CODE, invalidJson);
    }
};
