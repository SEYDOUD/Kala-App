const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const commandeController = require('../controllers/commande.controller');
const { authMiddleware, checkUserType } = require('../middlewares/auth.middleware');

// Validation pour crÃƒÆ’Ã‚Â©er une commande
const createCommandeValidation = [
  body('items').isArray().withMessage('Items doit ÃƒÆ’Ã‚Âªtre un tableau'),
  body('montant_total').isNumeric().withMessage('Montant total invalide'),
  body('mode_paiement').isIn(['wave', 'orange_money', 'carte_visa', 'especes'])
    .withMessage('Mode de paiement invalide'),
];

// Routes protÃƒÆ’Ã‚Â©gÃƒÆ’Ã‚Â©es (client uniquement)
router.post('/', authMiddleware, checkUserType('client'), createCommandeValidation, commandeController.createCommande);
router.post('/payment', authMiddleware, checkUserType('client'), commandeController.processPayment);
router.post(
  '/:id/retours',
  authMiddleware,
  checkUserType('client'),
  [
    body('description')
      .isString()
      .trim()
      .isLength({ min: 5, max: 1200 })
      .withMessage('Description retour invalide (5-1200 caracteres)'),
    body('photos')
      .optional()
      .isArray({ max: 5 })
      .withMessage('photos doit etre un tableau (max 5)'),
  ],
  commandeController.createRetour
);
router.post(
  '/:id/commentaires',
  authMiddleware,
  checkUserType('client'),
  [
    body('texte')
      .isString()
      .trim()
      .isLength({ min: 3, max: 1200 })
      .withMessage('Commentaire invalide (3-1200 caracteres)'),
  ],
  commandeController.createCommentaireClient
);
router.patch(
  '/:id/resultat-couture',
  authMiddleware,
  checkUserType('admin'),
  [
    body('photos')
      .optional()
      .isArray({ max: 10 })
      .withMessage('photos doit etre un tableau (max 10)'),
    body('videos')
      .optional()
      .isArray({ max: 5 })
      .withMessage('videos doit etre un tableau (max 5)'),
  ],
  commandeController.updateResultatCouture
);
router.patch(
  '/:id/retours/:retourId',
  authMiddleware,
  checkUserType('admin'),
  [
    body('statut')
      .isIn(['demande', 'en_traitement', 'resolu', 'rejete'])
      .withMessage('Statut retour invalide'),
    body('commentaire_admin')
      .optional()
      .isString()
      .trim()
      .isLength({ max: 800 })
      .withMessage('Commentaire admin invalide (max 800 caracteres)'),
  ],
  commandeController.updateRetourStatus
);
router.patch(
  '/:id/satisfaction',
  authMiddleware,
  checkUserType('client'),
  [
    body('satisfait')
      .optional()
      .isBoolean()
      .withMessage('satisfait doit etre un booleen'),
    body('commentaire')
      .optional()
      .isString()
      .trim()
      .isLength({ max: 800 })
      .withMessage('commentaire invalide (max 800 caracteres)'),
  ],
  commandeController.validateCommandeSatisfaction
);
router.get('/', authMiddleware, checkUserType('client', 'admin'), commandeController.getCommandesByClient);
router.get('/:id', authMiddleware, commandeController.getCommandeById);
router.patch('/:id/status', authMiddleware, checkUserType('admin'), commandeController.updateCommandeStatus);

module.exports = router;
