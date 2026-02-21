const mongoose = require('mongoose');

const commandeSchema = new mongoose.Schema({
  numero_commande: {
    type: String,
    unique: true
  },
  id_client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true
  },
  items: [{
    id_modele: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Modele',
      required: true
    },
    quantite: {
      type: Number,
      required: true,
      min: 1
    },
    prix_unitaire: {
      type: Number,
      required: true
    },
    tissus: [{
      id_tissu: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Tissu'
      },
      metrage: Number,
      prix_unitaire: Number,
      sous_total: Number
    }],
    id_mesure: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Mesure'
    },
    note: String,
    sous_total: {
      type: Number,
      required: true
    }
  }],
  sous_total: {
    type: Number,
    required: true
  },
  frais_livraison: {
    type: Number,
    default: 1500
  },
  montant_total: {
    type: Number,
    required: true
  },
  statut: {
    type: String,
    enum: ['en_attente', 'confirmee', 'en_cours', 'prete', 'livree', 'annulee'],
    default: 'en_attente'
  },
  statut_paiement: {
    type: String,
    enum: ['en_attente', 'paye', 'echoue', 'rembourse'],
    default: 'en_attente'
  },
  mode_paiement: {
    type: String,
    enum: ['wave', 'orange_money', 'carte_visa', 'especes'],
    required: true
  },
  reference_paiement: String,
  adresse_livraison: {
    rue: String,
    ville: String,
    quartier: String,
    telephone: String
  },
  date_livraison_estimee: Date,
  notes_admin: String
}, {
  timestamps: true,
  collection: 'commande'
});

// Générer le numéro de commande automatiquement AVANT validation
commandeSchema.pre('validate', async function(next) {
  if (!this.numero_commande) {
    const count = await mongoose.model('Commande').countDocuments();
    const date = new Date();
    const year = date.getFullYear().toString().slice(-2);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const numero = (count + 1).toString().padStart(4, '0');
    this.numero_commande = `CMD${year}${month}${numero}`;
  }
  next();
});

module.exports = mongoose.model('Commande', commandeSchema);