const mongoose = require('mongoose');

const atelierSchema = new mongoose.Schema({
  id_prestataire: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Prestataire',
    required: [true, 'Le prestataire est requis']
  },
  nom_atelier: {
    type: String,
    required: [true, 'Le nom de l\'atelier est requis'],
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  adresse: {
    type: String,
    trim: true
  }
}, {
  timestamps: true,
  collection: 'atelier'
});

module.exports = mongoose.model('Atelier', atelierSchema);