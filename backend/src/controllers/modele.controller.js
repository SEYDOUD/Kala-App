const Modele = require('../models/Modele');
const Atelier = require('../models/Atelier');

// Obtenir tous les modèles (publique)
exports.getAllModeles = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      genre,
      search,
      prixMin,
      prixMax,
      atelier
    } = req.query;

    // Construire le filtre
    const filter = { actif: true };
    
    if (genre) filter.genre = genre;
    if (atelier) filter.id_atelier = atelier;
    
    if (prixMin || prixMax) {
      filter.prix = {};
      if (prixMin) filter.prix.$gte = Number(prixMin);
      if (prixMax) filter.prix.$lte = Number(prixMax);
    }
    
    if (search) {
      filter.$text = { $search: search };
    }

    // Récupérer les modèles avec pagination
    const modeles = await Modele.find(filter)
      .populate({
        path: 'id_atelier',
        select: 'nom_atelier description',
        populate: {
          path: 'id_prestataire',
          select: 'username email telephone'
        }
      })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await Modele.countDocuments(filter);

    res.json({
      modeles,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des modèles:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des modèles',
      message: error.message
    });
  }
};

// Obtenir un modèle par ID
exports.getModeleById = async (req, res) => {
  try {
    const modele = await Modele.findById(req.params.id)
      .populate({
        path: 'id_atelier',
        select: 'nom_atelier description adresse',
        populate: {
          path: 'id_prestataire',
          select: 'username email telephone'
        }
      });

    if (!modele) {
      return res.status(404).json({
        error: 'Modèle non trouvé'
      });
    }

    res.json(modele);
  } catch (error) {
    console.error('Erreur lors de la récupération du modèle:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du modèle',
      message: error.message
    });
  }
};

// Créer un modèle (protégé - prestataire uniquement)
exports.createModele = async (req, res) => {
  try {
    const {
      nom,
      description,
      genre,
      duree_conception,
      prix,
      images
    } = req.body;

    // Vérifier que l'utilisateur est un prestataire
    let atelier;

    if (req.userType === 'prestataire') {
      atelier = await Atelier.findOne({ id_prestataire: req.userId });
    } else if (req.userType === 'admin') {
      atelier = await Atelier.findById(req.body.id_atelier);
    } else {

      return res.status(403).json({
        error: 'Seuls les prestataires ou admins peuvent créer des modèles'
      });
    }
    
    if (!atelier) {
      return res.status(404).json({
        error: 'Atelier non trouvé. Veuillez créer un atelier d\'abord.'
      });
    }

    // Créer le modèle
    const modele = new Modele({
      id_atelier: atelier._id,
      nom,
      description,
      genre,
      duree_conception,
      prix,
      images: images || []
    });

    await modele.save();

    // Peupler les données de l'atelier
    await modele.populate({
      path: 'id_atelier',
      select: 'nom_atelier description',
      populate: {
        path: 'id_prestataire',
        select: 'username email'
      }
    });

    res.status(201).json({
      message: 'Modèle créé avec succès',
      modele
    });
  } catch (error) {
    console.error('Erreur lors de la création du modèle:', error);
    res.status(500).json({
      error: 'Erreur lors de la création du modèle',
      message: error.message
    });
  }
};

// Mettre à jour un modèle (protégé - prestataire uniquement)
exports.updateModele = async (req, res) => {
  try {
    const modele = await Modele.findById(req.params.id).populate('id_atelier');

    if (!modele) {
      return res.status(404).json({
        error: 'Modèle non trouvé'
      });
    }

    // Vérifier que l'utilisateur est le propriétaire (ou admin)
    if (req.userType !== 'admin' && modele.id_atelier.id_prestataire.toString() !== req.userId.toString()) {
      return res.status(403).json({
        error: 'Non autorisé à modifier ce modèle'
      });
    }

    // Mettre à jour
    Object.assign(modele, req.body);
    await modele.save();

    res.json({
      message: 'Modèle mis à jour avec succès',
      modele
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du modèle:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du modèle',
      message: error.message
    });
  }
};

// Obtenir tous les modèles pour admin (actifs + inactifs)
exports.getAllModelesForAdmin = async (req, res) => {
  try {
    const { page = 1, limit = 100, genre, search, atelier } = req.query;

    const filter = {};
    if (genre) filter.genre = genre;
    if (atelier) filter.id_atelier = atelier;
    if (search) filter.$text = { $search: search };

    const modeles = await Modele.find(filter)
      .populate({
        path: 'id_atelier',
        select: 'nom_atelier description',
      })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await Modele.countDocuments(filter);

    res.json({
      modeles,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Obtenir la liste des ateliers pour admin
exports.getAllAteliersForAdmin = async (req, res) => {
  try {
    const ateliers = await Atelier.find({})
      .select('nom_atelier description adresse')
      .sort({ nom_atelier: 1 });

    res.json({
      ateliers,
      total: ateliers.length,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



// Supprimer un modèle (protégé - prestataire uniquement)
exports.deleteModele = async (req, res) => {
  try {
    const modele = await Modele.findById(req.params.id).populate('id_atelier');

    if (!modele) {
      return res.status(404).json({
        error: 'Modèle non trouvé'
      });
    }

    // Vérifier que l'utilisateur est le propriétaire (ou admin)
    if (req.userType !== 'admin' && modele.id_atelier.id_prestataire.toString() !== req.userId.toString()) {
      return res.status(403).json({
        error: 'Non autorisé à supprimer ce modèle'
      });
    }

    await modele.deleteOne();

    res.json({
      message: 'Modèle supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la suppression du modèle:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression du modèle',
      message: error.message
    });
  }
};

// Obtenir les modèles d'un atelier spécifique
exports.getModelesByAtelier = async (req, res) => {
  try {
    const { atelierId } = req.params;
    
    const modeles = await Modele.find({ 
      id_atelier: atelierId,
      actif: true 
    }).populate('id_atelier', 'nom_atelier description');

    res.json({
      modeles,
      total: modeles.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des modèles de l\'atelier:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des modèles',
      message: error.message
    });
  }
};