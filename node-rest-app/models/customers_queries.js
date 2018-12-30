const Customers = require('./customers');

exports.create = async function(_name,_email,_phone){
  try{return await Customers.create({name:_name,email:_email,phone:_phone});}
  catch(err){throw err};
}

exports.listAll = async function(){
  return await Customers.find({});
}

exports.find = async function(str){
  return await Customers.find({name: {"$regex": str, "$options":"i"}});
}