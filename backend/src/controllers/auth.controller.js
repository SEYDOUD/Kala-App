const { validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const Client = require('../models/Client');
const Prestataire = require('../models/Prestataire');
const Admin = require('../models/Admin');

// Générer un token JWT
const generateToken = (userId, userType) => {
  return jwt.sign(
    { userId, userType },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

// Inscription Client
exports.registerClient = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const { prenom, nom, username, password, email, telephone, adresse, date_naissance } = req.body;

    // Vérifier si l'email ou le username existe déjà
    const existingClient = await Client.findOne({ $or: [{ email }, { username }] });
    if (existingClient) {
      return res.status(409).json({
        error: 'Cet email ou nom d\'utilisateur est déjà utilisé'
      });
    }

    // Créer le client
    const client = new Client({
      prenom,
      nom,
      username,
      password,
      email,
      telephone,
      adresse,
      date_naissance
    });

    await client.save();

    // Générer le token
    const token = generateToken(client._id, 'client');

    res.status(201).json({
      message: 'Inscription réussie',
      user: client.toJSON(),
      userType: 'client',
      token
    });
  } catch (error) {
    console.error('Erreur lors de l\'inscription client:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'inscription',
      message: error.message
    });
  }
};

// Inscription Prestataire
exports.registerPrestataire = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const { username, password, email, telephone } = req.body;

    // Vérifier si l'email ou le username existe déjà
    const existingPrestataire = await Prestataire.findOne({ $or: [{ email }, { username }] });
    if (existingPrestataire) {
      return res.status(409).json({
        error: 'Cet email ou nom d\'utilisateur est déjà utilisé'
      });
    }

    // Créer le prestataire
    const prestataire = new Prestataire({
      username,
      password,
      email,
      telephone
    });

    await prestataire.save();

    // Générer le token
    const token = generateToken(prestataire._id, 'prestataire');

    res.status(201).json({
      message: 'Inscription réussie',
      user: prestataire.toJSON(),
      userType: 'prestataire',
      token
    });
  } catch (error) {
    console.error('Erreur lors de l\'inscription prestataire:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'inscription',
      message: error.message
    });
  }
};

// Connexion universelle (Client, Prestataire ou Admin)
exports.login = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const { username, password } = req.body;

    // Chercher dans Client
    let user = await Client.findOne({ username }).select('+password');
    let userType = 'client';

    // Si pas trouvé, chercher dans Prestataire
    if (!user) {
      user = await Prestataire.findOne({ username }).select('+password');
      userType = 'prestataire';
    }

    // Si pas trouvé, chercher dans Admin
    if (!user) {
      user = await Admin.findOne({ username }).select('+password');
      userType = 'admin';
    }

    // Si toujours pas trouvé
    if (!user) {
      return res.status(401).json({
        error: 'Nom d\'utilisateur ou mot de passe incorrect'
      });
    }

    // Vérifier le mot de passe
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Nom d\'utilisateur ou mot de passe incorrect'
      });
    }

    // Générer le token
    const token = generateToken(user._id, userType);

    res.json({
      message: 'Connexion réussie',
      user: user.toJSON(),
      userType,
      token
    });
  } catch (error) {
    console.error('Erreur lors de la connexion:', error);
    res.status(500).json({
      error: 'Erreur lors de la connexion',
      message: error.message
    });
  }
};

// Obtenir le profil de l'utilisateur connecté
exports.getProfile = async (req, res) => {
  try {
    res.json({
      user: req.user,
      userType: req.userType
    });
  } catch (error) {
    res.status(500).json({
      error: 'Erreur lors de la récupération du profil',
      message: error.message
    });
  }
};