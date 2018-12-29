const Customers = require('../models/customers');
const _ = require("lodash");
//MIKKEL: again, redundant code. I see the same cath for every route.
//Could this be shorter in some way ?
function trim_customer(c){
  return {name: c.name, email: c.email, phone: c.phone};
}

exports.get_all=function(req,res,next){
  Customers.find({}).then(function(customers){
    let all_customers = _.map(customers, trim_customer);
    res.json({status:200, message:"Ok.", datafield:all_customers});
  })
  .catch(function(err){
    next(err);
  });
};

exports.insert_customer=function(req, res, next) {
    //MIKKEL: I don't like the idea of putting this query directly
    // into the rest method. What if this function were to be used
    // from somewhere else ? Then you'd have to write the function all over again
    Customers.create({name: req.body.name,
                      email: req.body.email,
                      phone: req.body.phone})
              .then(function(ok){
                res.json({
                  status: 200,
                  message: "Customer added.",
                  datafield: null
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
            res.json({status:200, message:"Ok.", datafield:all_customers});
         })
         .catch(function(err){
          next(err);
         });
};
