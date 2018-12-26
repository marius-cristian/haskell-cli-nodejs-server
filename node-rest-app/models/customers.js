const mongoose = require('mongoose');
const Schema = mongoose.Schema;

let CustomerSchema = new Schema({
    name: {type: String, required: true, index: true},
    email: {type: String, required: true},
    phone: {type: String, requried: true}
});


// Export the model
module.exports = mongoose.model('Customer', CustomerSchema);