const Customers = require('../models/customers');
const _ = require("lodash");

function trim_customer(c){
  return {name: c.name, email: c.email, phone: c.phone};
}

exports.get_all=function(req,res,next){
  Customers.find({}).then(function(customers){
    let all_customers = _.map(customers, trim_customer);
    res.json({status:200, message:"Ok.", data:all_customers});
  })
  .catch(function(err){
    next(err);
  });
};

exports.insert_customer=function(req, res, next) {
    Customers.create({name: req.body.name,
                      email: req.body.email,
                      phone: req.body.phone})
              .then(function(ok){
                res.json({
                  status: 200,
                  message: "Customer added.",
                  data: null
                });
              })
              .catch(function(err){
                next(err);
              });
};

exports.find_customer=function(req, res, next){
Customers.find({name: {"$regex": req.params.str, "$options":"i"}})
         .then(function(customers){
            let all_customers = _.map(customers, trim_customer);
            res.json({status:200, message:"Ok.", data:all_customers});
         })
         .catch(function(err){
          next(err);
         });
};