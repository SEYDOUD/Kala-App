const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoUri =
      process.env.MONGODB_URI ||
      process.env.MONGO_URI ||
      process.env.DATABASE_URL;

    if (!mongoUri) {
      throw new Error(
        'Aucune URI MongoDB definie. Configurez MONGODB_URI (ou MONGO_URI / DATABASE_URL).'
      );
    }

    const conn = await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 5000,
    });

    console.log('MongoDB Atlas connecte avec succes.');
    console.log(`Host: ${conn.connection.host}`);
    console.log(`Base de donnees: ${conn.connection.name}`);
  } catch (error) {
    console.error('Erreur de connexion MongoDB:', error.message);
    process.exit(1);
  }
};

mongoose.connection.on('connected', () => {
  console.log('Mongoose connecte a MongoDB Atlas');
});

mongoose.connection.on('error', (err) => {
  console.error('Erreur Mongoose:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('Mongoose deconnecte de MongoDB Atlas');
});

process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('Connexion MongoDB fermee suite a l arret de l application');
  process.exit(0);
});

module.exports = connectDB;
