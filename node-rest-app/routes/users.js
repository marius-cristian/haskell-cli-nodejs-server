var express = require('express');
var router = express.Router();

var user_controller = require('../controllers/users');

router.post('/register', user_controller.user_create);
router.post('/authenticate', user_controller.user_authenticate);

module.exports = router;