const Mesure = require('../models/Mesure');

// Recuperer toutes les mesures d'un client
exports.getMesuresByClient = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent acceder aux mesures'
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
    console.error('Erreur lors de la recuperation des mesures:', error);
    res.status(500).json({ error: error.message });
  }
};

// Recuperer une mesure par ID
exports.getMesureById = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvee' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorise' });
    }

    res.json(mesure);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Creer une nouvelle mesure
exports.createMesure = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent creer des mesures'
      });
    }

    const mesureData = {
      ...req.body,
      id_client: req.userId
    };

    if (mesureData.est_par_defaut) {
      await Mesure.updateMany(
        { id_client: req.userId },
        { est_par_defaut: false }
      );
    }

    const mesure = new Mesure(mesureData);
    await mesure.save();

    res.status(201).json({
      message: 'Mesure creee avec succes',
      mesure
    });
  } catch (error) {
    console.error('Erreur lors de la creation de la mesure:', error);
    res.status(500).json({ error: error.message });
  }
};

// Mettre a jour une mesure
exports.updateMesure = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvee' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorise' });
    }

    if (req.body.est_par_defaut) {
      await Mesure.updateMany(
        { id_client: req.userId },
        { est_par_defaut: false }
      );
    }

    Object.assign(mesure, req.body);
    await mesure.save();

    res.json({
      message: 'Mesure mise a jour',
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
      return res.status(404).json({ error: 'Mesure non trouvee' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorise' });
    }

    await mesure.deleteOne();

    res.json({ message: 'Mesure supprimee' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Definir une mesure comme par defaut
exports.setMesureParDefaut = async (req, res) => {
  try {
    const mesure = await Mesure.findById(req.params.id);

    if (!mesure) {
      return res.status(404).json({ error: 'Mesure non trouvee' });
    }

    if (mesure.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorise' });
    }

    await Mesure.updateMany(
      { id_client: req.userId },
      { est_par_defaut: false }
    );

    mesure.est_par_defaut = true;
    await mesure.save();

    res.json({
      message: 'Mesure definie par defaut',
      mesure
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};