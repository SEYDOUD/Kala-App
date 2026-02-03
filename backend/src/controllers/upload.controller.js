const cloudinary = require('../config/cloudinary');

// Upload une image
exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'Aucune image fournie'
      });
    }

    res.json({
      message: 'Image uploadée avec succès',
      image: {
        url: req.file.path,
        publicId: req.file.filename,
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'upload:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'upload de l\'image',
      message: error.message
    });
  }
};

// Upload plusieurs images
exports.uploadMultipleImages = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        error: 'Aucune image fournie'
      });
    }

    const images = req.files.map(file => ({
      url: file.path,
      publicId: file.filename,
    }));

    res.json({
      message: 'Images uploadées avec succès',
      images
    });
  } catch (error) {
    console.error('Erreur lors de l\'upload:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'upload des images',
      message: error.message
    });
  }
};

// Supprimer une image
exports.deleteImage = async (req, res) => {
  try {
    const { publicId } = req.body;

    if (!publicId) {
      return res.status(400).json({
        error: 'Public ID requis'
      });
    }

    await cloudinary.uploader.destroy(publicId);

    res.json({
      message: 'Image supprimée avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la suppression:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression de l\'image',
      message: error.message
    });
  }
};