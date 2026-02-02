const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');

// Validation pour l'inscription client
const registerClientValidation = [
  body('prenom').trim().notEmpty().withMessage('Le prénom est requis'),
  body('nom').trim().notEmpty().withMessage('Le nom est requis'),
  body('username').trim().notEmpty().withMessage('Le nom d\'utilisateur est requis'),
  body('email').isEmail().withMessage('Email invalide'),
  body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('telephone').notEmpty().withMessage('Le téléphone est requis')
];

// Validation pour l'inscription prestataire + atelier
const registerPrestataireValidation = [
  body('username').trim().notEmpty().withMessage('Le nom d\'utilisateur est requis'),
  body('email').isEmail().withMessage('Email invalide'),
  body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('telephone').notEmpty().withMessage('Le téléphone est requis'),
  body('nom_atelier').trim().notEmpty().withMessage('Le nom de l\'atelier est requis'), // ← AJOUT
];

// Validation pour la connexion
const loginValidation = [
  body('username').notEmpty().withMessage('Le nom d\'utilisateur est requis'),
  body('password').notEmpty().withMessage('Le mot de passe est requis')
];

// Routes publiques
router.post('/register/client', registerClientValidation, authController.registerClient);
router.post('/register/prestataire', registerPrestataireValidation, authController.registerPrestataire);
router.post('/login', loginValidation, authController.login);

// Routes protégées
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;