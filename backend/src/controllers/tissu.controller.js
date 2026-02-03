const Tissu = require('../models/Tissu');

// Récupérer tous les tissus
exports.getAllTissus = async (req, res) => {
  try {
    const { genre, search, page = 1, limit = 20 } = req.query;

    const filter = { actif: true };
    if (genre) filter.genre = genre;

    const tissus = await Tissu.find(filter)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await Tissu.countDocuments(filter);

    res.json({
      tissus,
      total,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Récupérer un tissu par ID
exports.getTissuById = async (req, res) => {
  try {
    const tissu = await Tissu.findById(req.params.id);
    if (!tissu) {
      return res.status(404).json({ error: 'Tissu non trouvé' });
    }
    res.json(tissu);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Créer un tissu (admin uniquement)
exports.createTissu = async (req, res) => {
  try {
    if (req.userType !== 'admin') {
      return res.status(403).json({ error: 'Seuls les admins peuvent créer des tissus' });
    }

    const { nom, description, genre, prix, couleur, type_metrage, base_metrage, images } = req.body;

    const tissu = new Tissu({
      id_admin: req.userId,
      nom,
      description,
      genre,
      prix,
      couleur,
      type_metrage,
      base_metrage,
      images: images || []
    });

    await tissu.save();

    res.status(201).json({
      message: 'Tissu créé avec succès',
      tissu
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Mettre à jour un tissu
exports.updateTissu = async (req, res) => {
  try {
    if (req.userType !== 'admin') {
      return res.status(403).json({ error: 'Seuls les admins peuvent modifier des tissus' });
    }

    const tissu = await Tissu.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!tissu) {
      return res.status(404).json({ error: 'Tissu non trouvé' });
    }

    res.json({ message: 'Tissu mis à jour', tissu });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Supprimer un tissu
exports.deleteTissu = async (req, res) => {
  try {
    if (req.userType !== 'admin') {
      return res.status(403).json({ error: 'Seuls les admins peuvent supprimer des tissus' });
    }

    const tissu = await Tissu.findByIdAndDelete(req.params.id);
    if (!tissu) {
      return res.status(404).json({ error: 'Tissu non trouvé' });
    }

    res.json({ message: 'Tissu supprimé' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};