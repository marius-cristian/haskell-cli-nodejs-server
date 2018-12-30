const Users = require('../models/users_queries');
const bcrypt = require('bcrypt'); 
const jwt = require('jsonwebtoken');
const _ = require("lodash");

exports.user_create = function (req, res, next){
    Users.create(req.body.username,req.body.password)
        .then(function(ok){
            res.json({status:201, message:"User created.", datafield: null});
        })
        .catch(function(err){
            next(err);
        });
};

exports.user_authenticate = function (req, res, next){
    Users.findOne(req.body.username)
        .then(function(userInfo){
            switch(bcrypt.compareSync(req.body.password, userInfo.password)){
                case true:{
                    const token = jwt.sign({id: userInfo._id}, req.app.get('secretKey'),{ expiresIn: '1h' });
                    res.json({status:200, message: "Authenticated.", datafield:{user:
                        {_id:userInfo._id,username:userInfo.username}, token:token}});
                    break;
                }
                default:
                    res.json({status:409,message:"Invalid Password.",datafield:null});
            }; 
        })
        .catch(function(err){
            next(err);
        });
}