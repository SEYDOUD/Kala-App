const mongoose = require('mongoose');

const mesureSchema = new mongoose.Schema({
  id_client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: [true, 'Le client est requis']
  },
  nom_mesure: {
    type: String,
    required: [true, 'Le nom de la mesure est requis'],
    trim: true
  },
  genre: {
    type: String,
    enum: ['homme', 'femme'],
    required: [true, 'Le genre est requis']
  },
  // Informations de base
  taille_cm: {
    type: Number,
    required: true
  },
  poids_kg: {
    type: Number,
    required: true
  },
  age: {
    type: Number,
    required: true
  },
  // Mesures corporelles
  tour_de_tete: Number,
  epaule: Number,
  dos: Number,
  ventre: Number,
  abdomen: Number,
  cuisse: Number,
  entre_jambe: Number,
  entre_pied: Number,
  // Pour les femmes
  poitrine: Number,
  
  type_prise: {
    type: String,
    enum: ['ia', 'manuel'],
    default: 'manuel'
  },
  photo_url: String, // Si prise via IA
  est_par_defaut: {
    type: Boolean,
    default: false
  },
  actif: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  collection: 'mesure'
});

// Index
mesureSchema.index({ id_client: 1, actif: 1 });

module.exports = mongoose.model('Mesure', mesureSchema);