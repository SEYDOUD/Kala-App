const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const commandeController = require('../controllers/commande.controller');
const { authMiddleware, checkUserType } = require('../middlewares/auth.middleware');

// Validation pour créer une commande
const createCommandeValidation = [
  body('items').isArray().withMessage('Items doit être un tableau'),
  body('montant_total').isNumeric().withMessage('Montant total invalide'),
  body('mode_paiement').isIn(['wave', 'orange_money', 'carte_visa', 'especes'])
    .withMessage('Mode de paiement invalide'),
];

// Routes protégées (client uniquement)
router.post('/', authMiddleware, checkUserType('client'), createCommandeValidation, commandeController.createCommande);
router.post('/payment', authMiddleware, checkUserType('client'), commandeController.processPayment);
router.get('/', authMiddleware, checkUserType('client', 'admin'), commandeController.getCommandesByClient);
router.get('/:id', authMiddleware, commandeController.getCommandeById);
router.patch('/:id/status', authMiddleware, checkUserType('admin'), commandeController.updateCommandeStatus);

module.exports = router;