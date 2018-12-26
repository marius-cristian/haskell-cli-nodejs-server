const express = require('express');
const router = express.Router();

var customer_controller = require('../controllers/customers');

router.get('/', customer_controller.get_all);
router.get('/:str', customer_controller.find_customer);

router.post('/', customer_controller.insert_customer);

module.exports = router;