const Commande = require('../models/Commande');
// const Panier = require('../models/Panier'); // Si vous avez un modèle panier en base

// Créer une commande
exports.createCommande = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent créer des commandes'
      });
    }

    const {
      items,
      sous_total,
      frais_livraison,
      montant_total,
      mode_paiement,
      adresse_livraison
    } = req.body;

    // Créer la commande
    const commande = new Commande({
      id_client: req.userId,
      items,
      sous_total,
      frais_livraison: frais_livraison || 1500,
      montant_total,
      mode_paiement,
      adresse_livraison,
      statut: 'en_attente',
      statut_paiement: 'en_attente'
    });

    await commande.save();

    // Populer les données pour la réponse
    await commande.populate([
      { path: 'items.id_modele' },
      { path: 'items.tissus.id_tissu' },
      { path: 'items.id_mesure' }
    ]);

    res.status(201).json({
      message: 'Commande créée avec succès',
      commande
    });
  } catch (error) {
    console.error('Erreur lors de la création de la commande:', error);
    res.status(500).json({ error: error.message });
  }
};

// Simuler le paiement Wave/Orange Money
exports.processPayment = async (req, res) => {
  try {
    const { commandeId, mode_paiement, telephone } = req.body;

    const commande = await Commande.findById(commandeId);

    if (!commande) {
      return res.status(404).json({ error: 'Commande non trouvée' });
    }

    if (commande.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    // Simuler le paiement (en production, appeler l'API Wave/Orange Money)
    // Pour le développement, on marque juste comme payé
    commande.statut_paiement = 'paye';
    commande.statut = 'confirmee';
    commande.reference_paiement = `REF${Date.now()}`;
    
    await commande.save();

    res.json({
      message: 'Paiement effectué avec succès',
      commande,
      reference: commande.reference_paiement
    });
  } catch (error) {
    console.error('Erreur lors du paiement:', error);
    res.status(500).json({ error: error.message });
  }
};

// Récupérer les commandes du client
exports.getCommandesByClient = async (req, res) => {
  try {
    const commandes = await Commande.find({ id_client: req.userId })
      .populate([
        { path: 'items.id_modele' },
        { path: 'items.tissus.id_tissu' },
        { path: 'items.id_mesure' }
      ])
      .sort({ createdAt: -1 });

    res.json({
      commandes,
      total: commandes.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Récupérer une commande par ID
exports.getCommandeById = async (req, res) => {
  try {
    const commande = await Commande.findById(req.params.id)
      .populate([
        { path: 'items.id_modele' },
        { path: 'items.tissus.id_tissu' },
        { path: 'items.id_mesure' },
        { path: 'id_client' }
      ]);

    if (!commande) {
      return res.status(404).json({ error: 'Commande non trouvée' });
    }

    if (commande.id_client._id.toString() !== req.userId.toString() && 
        req.userType !== 'admin') {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    res.json(commande);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};