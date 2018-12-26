const express = require('express');
const router = express.Router();

const user_controller = require('../controllers/users');

router.post('/register', user_controller.user_create);
router.post('/authenticate', user_controller.user_authenticate);

module.exports = router;