class CommandeModel {
  final String id;
  final String numeroCommande;
  final String idClient;
  final List<CommandeItem> items;
  final double sousTotal;
  final double fraisLivraison;
  final double montantTotal;
  final String statut;
  final String statutCommande;
  final String statutPaiement;
  final String modePaiement;
  final String? referencePaiement;
  final DateTime createdAt;
  final DateTime? dateLivraisonEstimee;
  final List<CommandeRetour> retours;
  final CommandeValidationClient? validationClient;
  final List<String> resultatCouturePhotos;
  final List<String> resultatCoutureVideos;
  final List<CommandeCommentaire> commentairesClient;

  CommandeModel({
    required this.id,
    required this.numeroCommande,
    required this.idClient,
    required this.items,
    required this.sousTotal,
    required this.fraisLivraison,
    required this.montantTotal,
    required this.statut,
    required this.statutCommande,
    required this.statutPaiement,
    required this.modePaiement,
    this.referencePaiement,
    required this.createdAt,
    this.dateLivraisonEstimee,
    required this.retours,
    this.validationClient,
    required this.resultatCouturePhotos,
    required this.resultatCoutureVideos,
    required this.commentairesClient,
  });

  int get totalQuantite => items.fold<int>(0, (sum, item) => sum + item.quantite);

  double get totalArticlesCalcule =>
      items.fold<double>(0, (sum, item) => sum + item.sousTotal);

  String get statutGlobal {
    final normalized = statutCommande.toLowerCase();
    if (normalized == 'annulee' || normalized == 'annule') {
      return 'annulee';
    }
    if (normalized == 'livree' || normalized == 'terminee' || normalized == 'termine') {
      return 'terminee';
    }
    if (normalized == 'en_attente') {
      return 'en_attente';
    }
    return 'en_cours';
  }

  bool get estTerminee => statutGlobal == 'terminee';
  bool get estAnnulee => statutGlobal == 'annulee';
  bool get estLivree =>
      ['livree', 'terminee', 'termine'].contains(statut.toLowerCase());

  bool get clientASatisfait => validationClient?.satisfait ?? false;

  bool get hasResultatCouture =>
      resultatCouturePhotos.isNotEmpty || resultatCoutureVideos.isNotEmpty;

  bool get commentairesOuverts =>
      !clientASatisfait && !estAnnulee && !estTerminee;

  int get retoursRestants {
    final remaining = 3 - retours.length;
    if (remaining <= 0) {
      return 0;
    }
    return remaining;
  }

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDateLivraison;
    final rawDateLivraison = json['date_livraison_estimee'];
    if (rawDateLivraison is String && rawDateLivraison.isNotEmpty) {
      parsedDateLivraison = DateTime.tryParse(rawDateLivraison);
    }

    final rawValidation = json['validation_client'];
    final rawResultat = json['resultat_couture'];
    final rawResultPhotos =
        rawResultat is Map<String, dynamic> ? rawResultat['photos'] : null;
    final rawResultVideos =
        rawResultat is Map<String, dynamic> ? rawResultat['videos'] : null;

    return CommandeModel(
      id: json['_id'] ?? '',
      numeroCommande: json['numero_commande'] ?? '',
      idClient: json['id_client'] is String
          ? json['id_client']
          : (json['id_client']?['_id'] ?? ''),
      items: (json['items'] as List?)
              ?.map((item) => CommandeItem.fromJson(item))
              .toList() ??
          [],
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
      fraisLivraison: (json['frais_livraison'] ?? 1500).toDouble(),
      montantTotal: (json['montant_total'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'en_attente',
      statutCommande: json['statut_commande'] ??
          (json['statut'] ?? 'en_attente'),
      statutPaiement: json['statut_paiement'] ?? 'en_attente',
      modePaiement: json['mode_paiement'] ?? '',
      referencePaiement: json['reference_paiement'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      dateLivraisonEstimee: parsedDateLivraison,
      retours: (json['retours'] as List?)
              ?.map((retour) => CommandeRetour.fromJson(retour))
              .toList() ??
          const [],
      validationClient: rawValidation is Map<String, dynamic>
          ? CommandeValidationClient.fromJson(rawValidation)
          : null,
      resultatCouturePhotos: (rawResultPhotos as List?)
              ?.map((photo) => photo.toString().trim())
              .where((photo) => photo.isNotEmpty)
              .toList() ??
          const [],
      resultatCoutureVideos: (rawResultVideos as List?)
              ?.map((video) => video.toString().trim())
              .where((video) => video.isNotEmpty)
              .toList() ??
          const [],
      commentairesClient: (json['commentaires_client'] as List?)
              ?.map((commentaire) => CommandeCommentaire.fromJson(commentaire))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'sous_total': sousTotal,
      'frais_livraison': fraisLivraison,
      'montant_total': montantTotal,
      'mode_paiement': modePaiement,
    };
  }
}

class CommandeItem {
  final String idModele;
  final int quantite;
  final double prixUnitaire;
  final List<CommandeTissu> tissus;
  final String? idMesure;
  final String? note;
  final double sousTotal;
  final CommandeModeleInfo? modeleInfo;
  final CommandeMesureInfo? mesureInfo;

  CommandeItem({
    required this.idModele,
    required this.quantite,
    required this.prixUnitaire,
    required this.tissus,
    this.idMesure,
    this.note,
    required this.sousTotal,
    this.modeleInfo,
    this.mesureInfo,
  });

  String get displayModeleNom =>
      modeleInfo?.nom ?? (idModele.isNotEmpty ? 'Modele $idModele' : 'Modele');

  String get displayMesureNom {
    final nom = mesureInfo?.nomMesure;
    if (nom != null && nom.trim().isNotEmpty) {
      return nom;
    }
    if (idMesure != null && idMesure!.isNotEmpty) {
      return 'Mesure enregistree';
    }
    return 'Mesure non renseignee';
  }

  String? get imageUrl => modeleInfo?.imageUrl;
  List<String> get imageUrls => modeleInfo?.imageUrls ?? const [];

  double get totalTissus =>
      tissus.fold<double>(0, (sum, tissu) => sum + tissu.sousTotal);

  double get metrageTotal =>
      tissus.fold<double>(0, (sum, tissu) => sum + tissu.metrage);

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    final dynamic rawModele = json['id_modele'];
    final dynamic rawMesure = json['id_mesure'];

    return CommandeItem(
      idModele: rawModele is String ? rawModele : (rawModele?['_id'] ?? ''),
      quantite: json['quantite'] ?? 1,
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      tissus: (json['tissus'] as List?)
              ?.map((t) => CommandeTissu.fromJson(t))
              .toList() ??
          [],
      idMesure: rawMesure is String ? rawMesure : (rawMesure?['_id']),
      note: json['note'],
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
      modeleInfo: rawModele is Map<String, dynamic>
          ? CommandeModeleInfo.fromJson(rawModele)
          : null,
      mesureInfo: rawMesure is Map<String, dynamic>
          ? CommandeMesureInfo.fromJson(rawMesure)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_modele': idModele,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'tissus': tissus.map((t) => t.toJson()).toList(),
      if (idMesure != null) 'id_mesure': idMesure,
      if (note != null) 'note': note,
      'sous_total': sousTotal,
    };
  }
}

class CommandeModeleInfo {
  final String id;
  final String nom;
  final double? prix;
  final List<String> imageUrls;

  CommandeModeleInfo({
    required this.id,
    required this.nom,
    this.prix,
    required this.imageUrls,
  });

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory CommandeModeleInfo.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List?) ?? [];
    final imageUrls = <String>[];

    for (final image in rawImages) {
      if (image is Map) {
        final url = (image['url'] ?? '').toString().trim();
        if (url.isNotEmpty) {
          imageUrls.add(url);
        }
      } else if (image is String && image.trim().isNotEmpty) {
        imageUrls.add(image.trim());
      }
    }

    if (imageUrls.isEmpty) {
      final fallbackUrl = (json['image'] ?? '').toString().trim();
      if (fallbackUrl.isNotEmpty) {
        imageUrls.add(fallbackUrl);
      }
    }

    return CommandeModeleInfo(
      id: (json['_id'] ?? '').toString(),
      nom: (json['nom'] ?? 'Modele').toString(),
      prix: json['prix'] == null ? null : (json['prix'] as num).toDouble(),
      imageUrls: imageUrls,
    );
  }
}

class CommandeMesureInfo {
  final String id;
  final String nomMesure;
  final String? genre;
  final double? tailleCm;
  final double? poidsKg;
  final int? age;
  final double? tourDeTete;
  final double? epaule;
  final double? dos;
  final double? ventre;
  final double? abdomen;
  final double? cuisse;
  final double? entreJambe;
  final double? entrePied;
  final double? poitrine;

  CommandeMesureInfo({
    required this.id,
    required this.nomMesure,
    this.genre,
    this.tailleCm,
    this.poidsKg,
    this.age,
    this.tourDeTete,
    this.epaule,
    this.dos,
    this.ventre,
    this.abdomen,
    this.cuisse,
    this.entreJambe,
    this.entrePied,
    this.poitrine,
  });

  Map<String, double> get mesuresCorporelles {
    final mesures = <String, double>{};
    void addValue(String label, double? value) {
      if (value != null && value > 0) {
        mesures[label] = value;
      }
    }

    addValue('Tour de tete', tourDeTete);
    addValue('Epaule', epaule);
    addValue('Dos', dos);
    addValue('Ventre', ventre);
    addValue('Abdomen', abdomen);
    addValue('Cuisse', cuisse);
    addValue('Entre jambe', entreJambe);
    addValue('Entre pied', entrePied);
    addValue('Poitrine', poitrine);

    return mesures;
  }

  factory CommandeMesureInfo.fromJson(Map<String, dynamic> json) {
    return CommandeMesureInfo(
      id: (json['_id'] ?? '').toString(),
      nomMesure: (json['nom_mesure'] ?? '').toString(),
      genre: json['genre']?.toString(),
      tailleCm: (json['taille_cm'] as num?)?.toDouble(),
      poidsKg: (json['poids_kg'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      tourDeTete: (json['tour_de_tete'] as num?)?.toDouble(),
      epaule: (json['epaule'] as num?)?.toDouble(),
      dos: (json['dos'] as num?)?.toDouble(),
      ventre: (json['ventre'] as num?)?.toDouble(),
      abdomen: (json['abdomen'] as num?)?.toDouble(),
      cuisse: (json['cuisse'] as num?)?.toDouble(),
      entreJambe: (json['entre_jambe'] as num?)?.toDouble(),
      entrePied: (json['entre_pied'] as num?)?.toDouble(),
      poitrine: (json['poitrine'] as num?)?.toDouble(),
    );
  }
}

class CommandeTissu {
  final String idTissu;
  final double metrage;
  final double prixUnitaire;
  final double sousTotal;
  final CommandeTissuInfo? tissuInfo;

  CommandeTissu({
    required this.idTissu,
    required this.metrage,
    required this.prixUnitaire,
    required this.sousTotal,
    this.tissuInfo,
  });

  String get displayNom =>
      tissuInfo?.nom ?? (idTissu.isNotEmpty ? 'Tissu $idTissu' : 'Tissu');

  String? get displayCouleur => tissuInfo?.couleur;

  String? get imageUrl => tissuInfo?.imageUrl;

  factory CommandeTissu.fromJson(Map<String, dynamic> json) {
    final rawTissu = json['id_tissu'];

    return CommandeTissu(
      idTissu: rawTissu is String ? rawTissu : (rawTissu?['_id'] ?? ''),
      metrage: (json['metrage'] ?? 0).toDouble(),
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
      tissuInfo: rawTissu is Map<String, dynamic>
          ? CommandeTissuInfo.fromJson(rawTissu)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tissu': idTissu,
      'metrage': metrage,
      'prix_unitaire': prixUnitaire,
      'sous_total': sousTotal,
    };
  }
}

class CommandeTissuInfo {
  final String id;
  final String nom;
  final String? couleur;
  final String? typeMetrage;
  final List<String> imageUrls;

  CommandeTissuInfo({
    required this.id,
    required this.nom,
    this.couleur,
    this.typeMetrage,
    required this.imageUrls,
  });

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory CommandeTissuInfo.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List?) ?? [];
    final imageUrls = <String>[];

    for (final image in rawImages) {
      if (image is Map) {
        final url = (image['url'] ?? '').toString().trim();
        if (url.isNotEmpty) {
          imageUrls.add(url);
        }
      } else if (image is String && image.trim().isNotEmpty) {
        imageUrls.add(image.trim());
      }
    }

    return CommandeTissuInfo(
      id: (json['_id'] ?? '').toString(),
      nom: (json['nom'] ?? 'Tissu').toString(),
      couleur: json['couleur']?.toString(),
      typeMetrage: json['type_metrage']?.toString(),
      imageUrls: imageUrls,
    );
  }
}

class CommandeRetour {
  final String id;
  final String description;
  final List<String> photos;
  final String statut;
  final String? commentaireAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommandeRetour({
    required this.id,
    required this.description,
    required this.photos,
    required this.statut,
    this.commentaireAdmin,
    this.createdAt,
    this.updatedAt,
  });

  factory CommandeRetour.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CommandeRetour(
      id: (json['_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      photos: (json['photos'] as List?)
              ?.map((photo) => photo.toString().trim())
              .where((photo) => photo.isNotEmpty)
              .toList() ??
          const [],
      statut: (json['statut'] ?? 'demande').toString(),
      commentaireAdmin: json['commentaire_admin']?.toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class CommandeValidationClient {
  final bool satisfait;
  final DateTime? dateValidation;
  final String? commentaire;

  CommandeValidationClient({
    required this.satisfait,
    this.dateValidation,
    this.commentaire,
  });

  factory CommandeValidationClient.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date_validation'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return CommandeValidationClient(
      satisfait: json['satisfait'] == true,
      dateValidation: parsedDate,
      commentaire: json['commentaire']?.toString(),
    );
  }
}

class CommandeCommentaire {
  final String id;
  final String texte;
  final DateTime? createdAt;

  CommandeCommentaire({
    required this.id,
    required this.texte,
    this.createdAt,
  });

  factory CommandeCommentaire.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['created_at'] ?? json['createdAt'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return CommandeCommentaire(
      id: (json['_id'] ?? '').toString(),
      texte: (json['texte'] ?? '').toString(),
      createdAt: parsedDate,
    );
  }
}
