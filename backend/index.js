const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./src/config/database');
const authRoutes = require('./src/routes/auth.routes');
const modeleRoutes = require('./src/routes/modele.routes');
const uploadRoutes = require('./src/routes/upload.routes');
const tissuRoutes = require('./src/routes/tissu.routes');
const mesureRoutes = require('./src/routes/mesure.routes');
const commandeRoutes = require('./src/routes/commande.routes');
const visionRoutes = require('./src/routes/vision.routes');
const pawapayRoutes = require('./src/routes/pawapay.routes');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_PUBLIC_URL =
  process.env.APP_PUBLIC_URL ||
  process.env.FRONTEND_PUBLIC_URL ||
  '';

connectDB();

const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

app.get('/', (req, res) => {
  res.json({
    message: 'Bienvenue sur l\'API Kala App',
    service: 'Kala App API',
    version: '1.0.0',
    database: 'MongoDB Atlas',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      modeles: '/api/modeles',
      pawapayCallbacks: '/api/callbacks/pawapay',
      pawapayReturn: '/api/payments/pawapay/return',
      pawapayCancel: '/api/payments/pawapay/cancel',
    },
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/health', (req, res) => {
  const dbState = {
    0: 'Deconnecte',
    1: 'Connecte',
    2: 'En cours de connexion',
    3: 'En cours de deconnexion',
  };

  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: {
      status: dbState[require('mongoose').connection.readyState],
      name: require('mongoose').connection.name || 'Non connecte',
    },
  });
});

app.get('/api/payments/pawapay/return', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  const targetUrlJson = JSON.stringify(APP_PUBLIC_URL);
  res.send(`<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Paiement confirme</title>
  </head>
  <body style="font-family: Arial, sans-serif; padding: 24px;">
    <h3>Paiement traite</h3>
    <p>Vous pouvez fermer cette fenetre.</p>
    <script>
      (function () {
        const appUrl = ${targetUrlJson};
        try {
          const payload = {
            source: 'pawapay',
            type: 'return',
            query: Object.fromEntries(new URLSearchParams(window.location.search).entries())
          };
          if (window.opener && !window.opener.closed) {
            window.opener.postMessage(JSON.stringify(payload), '*');
            window.opener.focus();
          }
        } catch (e) {}
        setTimeout(function () {
          window.close();
          if (!window.closed && appUrl) {
            window.location.href = appUrl;
          }
        }, 700);
      })();
    </script>
  </body>
</html>`);
});

app.get('/api/payments/pawapay/cancel', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  const targetUrlJson = JSON.stringify(APP_PUBLIC_URL);
  res.send(`<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Paiement annule</title>
  </head>
  <body style="font-family: Arial, sans-serif; padding: 24px;">
    <h3>Paiement annule</h3>
    <p>Vous pouvez fermer cette fenetre.</p>
    <script>
      (function () {
        const appUrl = ${targetUrlJson};
        try {
          const payload = {
            source: 'pawapay',
            type: 'cancel',
            query: Object.fromEntries(new URLSearchParams(window.location.search).entries())
          };
          if (window.opener && !window.opener.closed) {
            window.opener.postMessage(JSON.stringify(payload), '*');
            window.opener.focus();
          }
        } catch (e) {}
        setTimeout(function () {
          window.close();
          if (!window.closed && appUrl) {
            window.location.href = appUrl;
          }
        }, 700);
      })();
    </script>
  </body>
</html>`);
});

app.use('/api/auth', authRoutes);
app.use('/api/modeles', modeleRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/tissus', tissuRoutes);
app.use('/api/mesures', mesureRoutes);
app.use('/api/commandes', commandeRoutes);
app.use('/api/vision', visionRoutes);
app.use('/api/callbacks/pawapay', pawapayRoutes);

app.use((req, res) => {
  res.status(404).json({
    error: 'Route non trouvee',
    path: req.path,
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Erreur interne du serveur',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Serveur demarre sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV}`);
  console.log(`URL: http://localhost:${PORT}`);
});

module.exports = app;
