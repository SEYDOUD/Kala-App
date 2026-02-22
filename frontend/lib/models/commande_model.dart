class CommandeModel {
  final String id;
  final String numeroCommande;
  final String idClient;
  final List<CommandeItem> items;
  final double sousTotal;
  final double fraisLivraison;
  final double montantTotal;
  final String statut;
  final String statutPaiement;
  final String modePaiement;
  final String? referencePaiement;
  final DateTime createdAt;

  CommandeModel({
    required this.id,
    required this.numeroCommande,
    required this.idClient,
    required this.items,
    required this.sousTotal,
    required this.fraisLivraison,
    required this.montantTotal,
    required this.statut,
    required this.statutPaiement,
    required this.modePaiement,
    this.referencePaiement,
    required this.createdAt,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['_id'] ?? '',
      numeroCommande: json['numero_commande'] ?? '',
      idClient: json['id_client'] is String
          ? json['id_client']
          : (json['id_client']?['_id'] ?? ''), // ← CORRECTION ICI
      items: (json['items'] as List?)
              ?.map((item) => CommandeItem.fromJson(item))
              .toList() ??
          [],
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
      fraisLivraison: (json['frais_livraison'] ?? 1500).toDouble(),
      montantTotal: (json['montant_total'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'en_attente',
      statutPaiement: json['statut_paiement'] ?? 'en_attente',
      modePaiement: json['mode_paiement'] ?? '',
      referencePaiement: json['reference_paiement'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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

  CommandeItem({
    required this.idModele,
    required this.quantite,
    required this.prixUnitaire,
    required this.tissus,
    this.idMesure,
    this.note,
    required this.sousTotal,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      idModele: json['id_modele'] is String
          ? json['id_modele']
          : (json['id_modele']?['_id'] ?? ''), // ← CORRECTION ICI
      quantite: json['quantite'] ?? 1,
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      tissus: (json['tissus'] as List?)
              ?.map((t) => CommandeTissu.fromJson(t))
              .toList() ??
          [],
      idMesure: json['id_mesure'] is String
          ? json['id_mesure']
          : (json['id_mesure']?['_id']), // ← CORRECTION ICI
      note: json['note'],
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
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

class CommandeTissu {
  final String idTissu;
  final double metrage;
  final double prixUnitaire;
  final double sousTotal;

  CommandeTissu({
    required this.idTissu,
    required this.metrage,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  factory CommandeTissu.fromJson(Map<String, dynamic> json) {
    return CommandeTissu(
      idTissu: json['id_tissu'] is String
          ? json['id_tissu']
          : (json['id_tissu']?['_id'] ?? ''), // ← CORRECTION ICI
      metrage: (json['metrage'] ?? 0).toDouble(),
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      sousTotal: (json['sous_total'] ?? 0).toDouble(),
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
