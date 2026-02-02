const mongoose = require('mongoose');

const modeleSchema = new mongoose.Schema({
  id_atelier: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Atelier',
    required: [true, 'L\'atelier est requis']
  },
  nom: {
    type: String,
    required: [true, 'Le nom du modèle est requis'],
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  genre: {
    type: String,
    enum: ['homme', 'femme', 'unisexe'],
    required: [true, 'Le genre est requis'],
    default: 'unisexe'
  },
  duree_conception: {
    type: Number, // en jours
    default: 7
  },
  prix: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix ne peut pas être négatif']
  },
  note_moyenne: {
    type: Number,
    min: 0,
    max: 5,
    default: 0
  },
  nombre_avis: {
    type: Number,
    default: 0
  },
  images: [{
    url: String,
    alt: String
  }],
  actif: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  collection: 'modele'
});

// Index pour la recherche
modeleSchema.index({ nom: 'text', description: 'text' });
modeleSchema.index({ genre: 1, actif: 1 });

module.exports = mongoose.model('Modele', modeleSchema);