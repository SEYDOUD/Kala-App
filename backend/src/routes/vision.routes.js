const express = require('express');
const { body } = require('express-validator');
const visionController = require('../controllers/vision.controller');

const router = express.Router();

const startValidation = [
  body('genre').isIn(['homme', 'femme']).withMessage('Genre invalide'),
  body('taille_cm').isNumeric().withMessage('taille_cm doit etre numerique'),
  body('poids_kg').isNumeric().withMessage('poids_kg doit etre numerique'),
  body('age').isNumeric().withMessage('age doit etre numerique'),
];

const analyzeValidation = [
  body('image_base64')
    .isString()
    .isLength({ min: 100 })
    .withMessage('image_base64 est requis'),
  body('confirm_capture')
    .optional()
    .isBoolean()
    .withMessage('confirm_capture doit etre un booleen'),
];

router.post('/session/start', startValidation, visionController.startVisionSession);
router.post(
  '/session/:session_id/analyze',
  analyzeValidation,
  visionController.analyzeVisionFrame
);
router.get('/session/:session_id', visionController.getVisionSession);

module.exports = router;
