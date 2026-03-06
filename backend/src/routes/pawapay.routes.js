const express = require('express');
const pawapayController = require('../controllers/pawapay.controller');

const router = express.Router();

router.get('/health', pawapayController.callbackHealth);
router.post('/deposits', pawapayController.depositCallback);
router.post('/payouts', pawapayController.payoutCallback);
router.post('/refunds', pawapayController.refundCallback);

module.exports = router;
