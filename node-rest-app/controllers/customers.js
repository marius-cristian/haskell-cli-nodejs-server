const Customers = require('../models/customers_queries');
const Handler = require('./generic_handler');
const _ = require("lodash");


function trim_customer(c){
  return {name: c.name, email: c.email, phone: c.phone};
}

exports.get_all=function(req,res,next){
  Handler.generic_handler(req,res,next,Customers.listAll(),(customers)=>{
    return _.map(customers,trim_customer);
  });
};

exports.insert_customer=function(req, res, next) {
  Handler.generic_handler(req,res,next,Customers.create(
    req.body.name, req.body.email, req.body.phone),(ok)=>{return null;});
};

exports.find_customer=function(req, res, next){
  Handler.generic_handler(req,res,next,Customers.find(req.params.str),(customers)=>{
    return _.map(customers, trim_customer);
  });
};
