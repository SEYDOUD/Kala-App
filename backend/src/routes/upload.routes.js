const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/upload.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');

// Upload une seule image
router.post(
  '/single',
  authMiddleware,
  upload.single('image'),
  uploadController.uploadImage
);

// Upload plusieurs images (max 5)
router.post(
  '/multiple',
  authMiddleware,
  upload.array('images', 5),
  uploadController.uploadMultipleImages
);

// Supprimer une image
router.delete(
  '/',
  authMiddleware,
  uploadController.deleteImage
);

module.exports = router;