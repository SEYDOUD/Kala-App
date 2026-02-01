const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Options recommandées
      serverSelectionTimeoutMS: 5000, // Timeout après 5 secondes
    });

    console.log('✅ MongoDB Atlas connecté avec succès !');
    console.log(`📊 Host: ${conn.connection.host}`);
    console.log(`📦 Base de données: ${conn.connection.name}`);
    
  } catch (error) {
    console.error('❌ Erreur de connexion MongoDB:', error.message);
    process.exit(1); // Arrêter l'application si la connexion échoue
  }
};

// Gestion des événements de connexion
mongoose.connection.on('connected', () => {
  console.log('🔗 Mongoose connecté à MongoDB Atlas');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Erreur Mongoose:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️  Mongoose déconnecté de MongoDB Atlas');
});

// Gestion de l'arrêt propre
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('👋 Connexion MongoDB fermée suite à l\'arrêt de l\'application');
  process.exit(0);
});

module.exports = connectDB;