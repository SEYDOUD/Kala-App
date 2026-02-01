const jwt = require('jsonwebtoken');
const Client = require('../models/Client');
const Prestataire = require('../models/Prestataire');
const Admin = require('../models/Admin');

const authMiddleware = async (req, res, next) => {
  try {
    // Récupérer le token depuis l'en-tête Authorization
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        error: 'Authentification requise',
        message: 'Aucun token fourni'
      });
    }

    // Vérifier le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Trouver l'utilisateur selon son type
    let user;
    const { userId, userType } = decoded;

    if (userType === 'client') {
      user = await Client.findById(userId);
    } else if (userType === 'prestataire') {
      user = await Prestataire.findById(userId);
    } else if (userType === 'admin') {
      user = await Admin.findById(userId);
    }

    if (!user) {
      return res.status(401).json({
        error: 'Authentification échouée',
        message: 'Utilisateur non trouvé'
      });
    }

    // Ajouter l'utilisateur et son type à la requête
    req.user = user;
    req.userType = userType;
    req.userId = userId;
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Token invalide'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expiré'
      });
    }
    res.status(500).json({
      error: 'Erreur d\'authentification',
      message: error.message
    });
  }
};

// Middleware pour vérifier le type d'utilisateur
const checkUserType = (...allowedTypes) => {
  return (req, res, next) => {
    if (!req.userType) {
      return res.status(401).json({
        error: 'Authentification requise'
      });
    }

    if (!allowedTypes.includes(req.userType)) {
      return res.status(403).json({
        error: 'Accès interdit',
        message: 'Vous n\'avez pas les permissions nécessaires'
      });
    }

    next();
  };
};

module.exports = { authMiddleware, checkUserType };