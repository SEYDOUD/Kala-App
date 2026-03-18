const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const modeleController = require('../controllers/modele.controller');
const { authMiddleware, checkUserType } = require('../middlewares/auth.middleware');

// Validation pour la creation de modele
const createModeleValidation = [
  body('nom').trim().notEmpty().withMessage('Le nom du modele est requis'),
  body('genre').isIn(['homme', 'femme', 'unisexe']).withMessage('Genre invalide'),
  body('type')
    .optional()
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Type invalide'),
  body('prix').isNumeric().withMessage('Le prix doit etre un nombre'),
  body('duree_conception')
    .optional()
    .isInt({ min: 1, max: 365 })
    .withMessage('La duree de conception doit etre un entier (1-365)'),
];

// Routes publiques
router.get('/', modeleController.getAllModeles);
router.get('/:id', modeleController.getModeleById);
router.get('/atelier/:atelierId', modeleController.getModelesByAtelier);

// Routes protegees (prestataire uniquement)
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

// Route protegee admin (liste complete)
router.get(
  '/admin/all',
  authMiddleware,
  checkUserType('admin'),
  modeleController.getAllModelesForAdmin
);

router.get(
  '/admin/ateliers',
  authMiddleware,
  checkUserType('admin'),
  modeleController.getAllAteliersForAdmin
);

router.get('/:id', modeleController.getModeleById);

module.exports = router;
