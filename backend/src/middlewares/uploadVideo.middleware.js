const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'kala-app/resultats-videos',
    resource_type: 'video',
    allowed_formats: ['mp4', 'mov', 'webm', 'm4v'],
  },
});

const uploadVideo = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max
  },
});

module.exports = uploadVideo;
