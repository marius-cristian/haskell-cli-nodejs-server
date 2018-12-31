const Users = require('../models/users_queries');
const bcrypt = require('bcrypt'); 
const jwt = require('jsonwebtoken');
const Handler = require('./generic_handler.js');
const _ = require("lodash");

exports.user_create = function (req, res, next){
    Handler.generic_handler(req,res,next,Users.create(
        req.body.username,req.body.password),(ok)=>{return null});
};

exports.user_authenticate = function (req, res, next){
    Handler.generic_handler(req,res,next,Users.findOne(req.body.username),
        (userInfo)=>{
            switch(bcrypt.compareSync(req.body.password, userInfo.password)){
                case true:{
                    const token = jwt.sign({id: userInfo._id}, req.app.get('secretKey'),{ expiresIn: '1h' });
                    return {user:{_id:userInfo._id,username:userInfo.username}, token:token};
                    break;
                }
                default:
                    return null;
            }      
        });
}