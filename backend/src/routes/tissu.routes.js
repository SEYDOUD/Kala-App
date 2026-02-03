const express = require('express');
const router = express.Router();
const tissuController = require('../controllers/tissu.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');

// Routes publiques
router.get('/', tissuController.getAllTissus);
router.get('/:id', tissuController.getTissuById);

// Routes protégées (admin uniquement)
router.post('/', authMiddleware, tissuController.createTissu);
router.put('/:id', authMiddleware, tissuController.updateTissu);
router.delete('/:id', authMiddleware, tissuController.deleteTissu);

module.exports = router;