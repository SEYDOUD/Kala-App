const mongoose = require('mongoose');

const tissuSchema = new mongoose.Schema({
  id_admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
  nom: {
    type: String,
    required: [true, 'Le nom du tissu est requis'],
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  genre: {
    type: String,
    enum: ['homme', 'femme', 'unisexe'],
    default: 'unisexe'
  },
  prix: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix ne peut pas être négatif']
  },
  couleur: {
    type: String,
    trim: true
  },
  type_metrage: {
    type: String,
    trim: true
  },
  base_metrage: {
    type: Number,
    default: 1
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
  collection: 'tissu'
});

tissuSchema.index({ genre: 1, actif: 1 });
tissuSchema.index({ nom: 'text', description: 'text' });

module.exports = mongoose.model('Tissu', tissuSchema);