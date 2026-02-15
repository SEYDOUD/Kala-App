const Mesure = require('../models/Mesure');

// Récupérer toutes les mesures d'un client
exports.getMesuresByClient = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent accéder aux mesures'
      });
    }

    const mesures = await Mesure.find({ 
      id_client: req.userId,
      actif: true 
    }).sort({ est_par_defaut: -1, createdAt: -1 });

    res.json({
      mesures,
      total: mesures.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des mesures:', error);
    res.status(500).json({ error: error.message });
  }
};

// Récupérer une mesure par ID
exports.getMesureById = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvée' });
    }

    // Vérifier que c'est bien le client propriétaire
    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    res.json(mesure);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Créer une nouvelle mesure
exports.createMesure = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent créer des mesures'
      });
    }

    const mesureData = {
      ...req.body,
      id_client: req.userId
    };

    // Si c'est marqué par défaut, retirer le défaut des autres
    if (mesureData.est_par_defaut) {
      await Mesure.updateMany(
        { id_client: req.userId },
        { est_par_defaut: false }
      );
    }

    const mesure = new Mesure(mesureData);
    await mesure.save();

    res.status(201).json({
      message: 'Mesure créée avec succès',
      mesure
    });
  } catch (error) {
    console.error('Erreur lors de la création de la mesure:', error);
    res.status(500).json({ error: error.message });
  }
};

// Mettre à jour une mesure
exports.updateMesure = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvée' });
    }

    // Vérifier que c'est bien le client propriétaire
    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    // Si on met cette mesure par défaut
    if (req.body.est_par_defaut) {
      await Mesure.updateMany(
        { id_client: req.userId },
        { est_par_defaut: false }
      );
    }

    Object.assign(mesure, req.body);
    await mesure.save();

    res.json({
      message: 'Mesure mise à jour',
      mesure
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Supprimer une mesure
exports.deleteMesure = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvée' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    await mesure.deleteOne();

    res.json({ message: 'Mesure supprimée' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Définir une mesure comme par défaut
exports.setMesureParDefaut = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvée' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    // Retirer le défaut des autres
    await Mesure.updateMany(
      { id_client: req.userId },
      { est_par_defaut: false }
    );

    // Mettre celle-ci par défaut
    mesure.est_par_defaut = true;
    await mesure.save();

    res.json({
      message: 'Mesure définie par défaut',
      mesure
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};