const Customers = require('../models/customers_queries');
const _ = require("lodash");
//MIKKEL: again, redundant code. I see the same cath for every route.
//Could this be shorter in some way ?
function trim_customer(c){
  return {name: c.name, email: c.email, phone: c.phone};
}

//MIKKEL Ok to to get rid of the try catch and the return of status 200 each
//time, I propose a function that handles the request..that takes
//the request and response as parameters, a function (of what to get or insert),
//returns {status 200, message ok,dataField:(what was retrieved)} if if "gets it",
// returns an error if it
// doesnt get it (in catch). That way there's an uniform way of handling request
// that will always return the same stuff
// and the number of lines in the program (and risk of bugs) will be shortened.
exports.get_all=function(req,res,next){
  Customers.listAll().then(function(customers){
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
    Customers.create(req.body.name,
                  .body.email,
                     req.body.phone)
              .then(function(ok){
                res.json({
                  //this is redundant, same lines of code as in find_customer
                  status: 200,
                  message: "Customer added.",
                  datafield: null
                });
              })

              //.catch(function(err){
              //  next(err);
              //});
};

exports.find_customer=function(req, res, next){
Customers.find(req.params.str)
         .then(function(customers){
            let all_customers = _.map(customers, trim_customer);
            res.json({status:200, message:"Ok.", datafield:all_customers});
         })
         //.catch(function(err){
         // next(err);
         //});
};
