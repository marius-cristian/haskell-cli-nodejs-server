const Users = require('./users');

exports.create = async function (uname, pwd){
  let user = {username: uname, password: pwd};
  try {return await Users.create(user);}
  catch(err){throw err;}
}

exports.findOne = async function (uname){
  try{return await Users.findOne({username:uname});}
  catch(err){cosnole.log(er);}
}