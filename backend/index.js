const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import de la connexion à la base de données
const connectDB = require('./src/config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Connexion à MongoDB Atlas
connectDB();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({
    message: '👋 Hello World from Backend!',
    service: 'Kala App API',
    version: '1.0.0',
    database: 'MongoDB Atlas',
    timestamp: new Date().toISOString()
  });
});

// Route de test pour vérifier la connexion DB
app.get('/api/health', (req, res) => {
  const dbState = {
    0: 'Déconnecté',
    1: 'Connecté',
    2: 'En cours de connexion',
    3: 'En cours de déconnexion'
  };

  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: {
      status: dbState[require('mongoose').connection.readyState],
      name: require('mongoose').connection.name || 'Non connecté'
    }
  });
});

// Gestion des erreurs 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Route non trouvée',
    path: req.path
  });
});

// Gestion des erreurs globales
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Erreur interne du serveur',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Démarrage du serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  console.log(`📍 Environnement: ${process.env.NODE_ENV}`);
  console.log(`🔗 URL: http://localhost:${PORT}`);
});

module.exports = app;