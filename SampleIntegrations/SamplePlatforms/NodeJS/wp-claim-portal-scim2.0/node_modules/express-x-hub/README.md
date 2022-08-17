Express X-Hub
=======================

[![Build Status](https://travis-ci.org/alexcurtis/express-x-hub.svg?branch=master)](https://travis-ci.org/alexcurtis/express-x-hub) [![Coverage Status](https://img.shields.io/coveralls/alexcurtis/express-x-hub.svg)](https://coveralls.io/r/alexcurtis/express-x-hub?branch=master)

X-Hub-Signature Express.js Middleware. A compact way to validate X-Hub requests to ensure they have not been tampered with. Particularly useful for Facebook real-time updates and GitHub web hooks.

## Getting Started
Install the middleware with this command:

```shell
npm install express-x-hub --save
```

Then add the middleware to Express.js. It needs to be one of the first and before `bodyParser()`.

```javascript
var xhub = require('express-x-hub');
app.use(xhub({ algorithm: 'sha1', secret: XHUB_SECRET_HERE }));
app.use(bodyParser());
app.use(methodOverride());
```

Where `XHUB_SECRET_HERE` is your platform's (facebook, github, etc) secret.

This will add some special sauce to your `req` object:

## Request Additions

### isXHub ```boolean```

Is the request X-Hub. Allows you to early reject any messages without XHub content.

```javascript
var isXHub = req.isXHub;
if(!isXHub) { return this.reject('No X-Hub Signature', req, res); }
```

### isXHubValid ```req.isXHubValid()```

Returns a boolean value. Validates the request body against the X-Hub signature using your secret.

```javascript
var isValid = req.isXHubValid();
if(!isValid){ return this.reject('Invalid X-Hub Request', req, res); }
```
If its valid, then the request has not been tampered with and you are safe to process it.


## Build

1. `npm test` - Run tests.
2. `gulp` - Lint and run tests.

## Example

Some very simple examples can be found in the `example` dir.

Start the server:

```shell
node ./example/server.js
```

Curl in an emulated X-Hub post:

```shell
sh ./example/curl_valid.sh
>> { "success": "X-Hub Is Valid" }

sh ./example/curl_invalid.sh
>> { "error": "X-Hub Is Invalid" }
```

## Options

### secret ```string``` - required

X-Hub secret that is used to validate the request body against the signed X-HUB signature on the header.

### algorithm ```string```

Encryption algorithm used to generate the signature. Defaults to `sha1`.

### limit ```string```

Limit on the request body size. Defaults to `100kb`.

### encoding ```string```

Encoding on the raw input stream. Defaults to `utf8`.

### strict ```boolean```

Strict demands on the JSON. Defaults to `true`.

### reviver ```function```

Reviver used during `JSON.parse`.

