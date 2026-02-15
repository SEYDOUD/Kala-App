const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const mesureController = require('../controllers/mesure.controller');
const { authMiddleware, checkUserType } = require('../middlewares/auth.middleware');

// Validation pour créer une mesure
const createMesureValidation = [
  body('nom_mesure').trim().notEmpty().withMessage('Le nom de la mesure est requis'),
  body('genre').isIn(['homme', 'femme']).withMessage('Genre invalide'),
  body('taille_cm').isNumeric().withMessage('La taille doit être un nombre'),
  body('poids_kg').isNumeric().withMessage('Le poids doit être un nombre'),
  body('age').isNumeric().withMessage('L\'âge doit être un nombre'),
];

// Routes protégées (client uniquement)
router.get('/', authMiddleware, checkUserType('client'), mesureController.getMesuresByClient);
router.get('/:id', authMiddleware, checkUserType('client'), mesureController.getMesureById);
router.post('/', authMiddleware, checkUserType('client'), createMesureValidation, mesureController.createMesure);
router.put('/:id', authMiddleware, checkUserType('client'), mesureController.updateMesure);
router.delete('/:id', authMiddleware, checkUserType('client'), mesureController.deleteMesure);
router.patch('/:id/defaut', authMiddleware, checkUserType('client'), mesureController.setMesureParDefaut);

module.exports = router;