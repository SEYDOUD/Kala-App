const { validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const Client = require('../models/Client');
const Prestataire = require('../models/Prestataire');
const Admin = require('../models/Admin');
const Atelier = require('../models/Atelier'); // ← AJOUT ICI

// Générer un token JWT
const generateToken = (userId, userType) => {
  return jwt.sign(
    { userId, userType },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

// Inscription Client (reste identique)
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

// Inscription Prestataire + Atelier (MODIFIÉ)
exports.registerPrestataire = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const { 
      username, 
      password, 
      email, 
      telephone,
      nom_atelier,      // ← AJOUT
      description,      // ← AJOUT
      adresse          // ← AJOUT
    } = req.body;

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

    // Créer l'atelier associé au prestataire
    const atelier = new Atelier({
      id_prestataire: prestataire._id,
      nom_atelier: nom_atelier || `Atelier de ${username}`, // Nom par défaut si non fourni
      description: description || '',
      adresse: adresse || ''
    });

    await atelier.save();

    // Générer le token
    const token = generateToken(prestataire._id, 'prestataire');

    res.status(201).json({
      message: 'Inscription réussie',
      user: prestataire.toJSON(),
      atelier: atelier.toJSON(), // ← AJOUT : renvoyer aussi l'atelier
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

// Connexion universelle (reste identique)
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

    // Si c'est un prestataire, récupérer aussi son atelier
    let atelier = null;
    if (userType === 'prestataire') {
      atelier = await Atelier.findOne({ id_prestataire: user._id });
    }

    // Générer le token
    const token = generateToken(user._id, userType);

    res.json({
      message: 'Connexion réussie',
      user: user.toJSON(),
      ...(atelier && { atelier: atelier.toJSON() }), // Ajouter l'atelier si c'est un prestataire
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
    // Si c'est un prestataire, récupérer aussi son atelier
    let atelier = null;
    if (req.userType === 'prestataire') {
      atelier = await Atelier.findOne({ id_prestataire: req.userId });
    }

    res.json({
      user: req.user,
      userType: req.userType,
      ...(atelier && { atelier: atelier.toJSON() })
    });
  } catch (error) {
    res.status(500).json({
      error: 'Erreur lors de la récupération du profil',
      message: error.message
    });
  }
};