var express = require('express'),
    glob = require('glob'),
    favicon = require('serve-favicon'),
    logger = require('morgan'),
    bodyParser = require('body-parser'),
    compress = require('compression'),
    methodOverride = require('method-override'),
    crypto = require('crypto'), 
    config = require("./config");

module.exports = function(app, config) {
  var env = config.env || 'development';
  app.locals.ENV = env;
  app.locals.ENV_DEVELOPMENT = env == 'development';

  app.use(favicon(config.root + '/public/img/favicon.ico'));

  app.use(logger('dev'));
  
  app.use(bodyParser.urlencoded({
    extended: true
  }));

  app.use(compress());
  app.use(express.static(config.root + '/public'));
  app.use(methodOverride());
  
  app.set('views', config.root + '/app/views');
  app.set('view engine', 'ejs');

  var controllers = glob.sync(config.root + '/app/controllers/*.js');
  controllers.forEach(function (controller) {
    require(controller)(app);
  });
};