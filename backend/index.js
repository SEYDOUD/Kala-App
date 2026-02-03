const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./src/config/database');
const authRoutes = require('./src/routes/auth.routes');
const modeleRoutes = require('./src/routes/modele.routes'); // ← AJOUT
const uploadRoutes = require('./src/routes/upload.routes');
const tissuRoutes = require('./src/routes/tissu.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Connexion à MongoDB Atlas
connectDB();

// Configuration CORS
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

// Middlewares
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({
    message: '👋 Bienvenue sur l\'API Kala App!',
    service: 'Kala App API',
    version: '1.0.0',
    database: 'MongoDB Atlas',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      modeles: '/api/modeles' // ← AJOUT
    },
    timestamp: new Date().toISOString()
  });
});

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

// Routes d'authentification
app.use('/api/auth', authRoutes);
// Routes des modèles
app.use('/api/modeles', modeleRoutes); // ← AJOUT
// Routes d'upload
app.use('/api/upload', uploadRoutes);
// Routes tissu
app.use('/api/tissus', tissuRoutes);

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