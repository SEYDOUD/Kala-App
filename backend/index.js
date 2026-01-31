const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Route principale
app.get('/', (req, res) => {
  res.json({
    message: '👋 Hello World from Backend!',
    service: 'Couture App API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Route de test
app.get('/api/test', (req, res) => {
  res.json({
    message: '✅ L\'API fonctionne correctement!',
    status: 'OK'
  });
});

// Démarrage du serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  console.log(`🔗 URL: http://localhost:${PORT}`);
});