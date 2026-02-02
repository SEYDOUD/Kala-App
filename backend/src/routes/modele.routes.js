const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const modeleController = require('../controllers/modele.controller');
const { authMiddleware, checkUserType } = require('../middlewares/auth.middleware');

// Validation pour la création de modèle
const createModeleValidation = [
  body('nom').trim().notEmpty().withMessage('Le nom du modèle est requis'),
  body('genre').isIn(['homme', 'femme', 'unisexe']).withMessage('Genre invalide'),
  body('prix').isNumeric().withMessage('Le prix doit être un nombre'),
];

// Routes publiques
router.get('/', modeleController.getAllModeles);
router.get('/:id', modeleController.getModeleById);
router.get('/atelier/:atelierId', modeleController.getModelesByAtelier);

// Routes protégées (prestataire uniquement)
router.post(
  '/', 
  authMiddleware, 
  checkUserType('prestataire', 'admin'),
  createModeleValidation,
  modeleController.createModele
);

router.put(
  '/:id', 
  authMiddleware, 
  checkUserType('prestataire', 'admin'),
  modeleController.updateModele
);

router.delete(
  '/:id', 
  authMiddleware, 
  checkUserType('prestataire', 'admin'),
  modeleController.deleteModele
);

module.exports = router;