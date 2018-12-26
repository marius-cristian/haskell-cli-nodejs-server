const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const bcrypt = require('bcrypt');
const saltRounds = 5;

let UserSchema = new Schema({
    username  : {type: String, required: true, max: 100, unique: true},
    password  : {type: String, required: true}
});

UserSchema.pre('save', function(next){
this.password = bcrypt.hashSync(this.password, saltRounds);
next();
});
// Export the model
module.exports = mongoose.model('User', UserSchema);