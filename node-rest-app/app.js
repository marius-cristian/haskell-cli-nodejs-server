const express = require('express');
const logger = require('morgan');
const movies = require('./routes/customers') ;
const users = require('./routes/users');
const bodyParser = require('body-parser');
const mongoose = require('./config/database');
var jwt = require('jsonwebtoken');
var Promise = require("bluebird");
const app = express();
app.set('secretKey', 'this_should_be_generated_in_an_env_var'); // jwt secret token
// connection to mongodb
mongoose.connection.on('error', console.error.bind(console, 'MongoDB connection error:'));
app.use(logger('dev'));
//app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());
app.get('/', function(req, res){
res.json({"message": "Landing Page"});
});
// public route
app.use('/users', users);
// private route
app.use('/customers', validate_user, movies);

function validate_user(req, res, next) {
  var jwtVerifyAsync = Promise.promisify(jwt.verify, jwt);
  jwtVerifyAsync.verify(req.headers['x-access-token'], req.app.get('secretKey'))
     .then(function(decoded){
      // add user id to request
      req.body.userId = decoded.id;
      next();
    })
    .catch(function(err){
      res.json({status:409, message: err.message, data:null});
    });
}

// handle 404 error
app.use(function(req, res, next) {
 let err = new Error('Not Found');
    err.status = 404;
    next(err);
});
// handle errors
app.use(function(err, req, res, next) {
  console.log(err);
  switch(err.status){
    case 404:
      res.status(404).json({status:404, message: "Not found", data:null});
      break;
    default:
      res.status(500).json({status:500, message: "Broken", data:null});
  } 
});
app.listen(3000, function(){
 console.log('Node server listening on port 3000');
});