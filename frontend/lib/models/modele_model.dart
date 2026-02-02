class ModeleModel {
  final String id;
  final String nom;
  final String? description;
  final String genre;
  final int dureeConception;
  final double prix;
  final double noteMoyenne;
  final int nombreAvis;
  final List<ImageModele> images;
  final bool actif;
  final AtelierInfo? atelier;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModeleModel({
    required this.id,
    required this.nom,
    this.description,
    required this.genre,
    required this.dureeConception,
    required this.prix,
    required this.noteMoyenne,
    required this.nombreAvis,
    required this.images,
    required this.actif,
    this.atelier,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModeleModel.fromJson(Map<String, dynamic> json) {
    return ModeleModel(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      genre: json['genre'] ?? 'unisexe',
      dureeConception: json['duree_conception'] ?? 7,
      prix: (json['prix'] ?? 0).toDouble(),
      noteMoyenne: (json['note_moyenne'] ?? 0).toDouble(),
      nombreAvis: json['nombre_avis'] ?? 0,
      images: (json['images'] as List? ?? [])
          .map((img) => ImageModele.fromJson(img))
          .toList(),
      actif: json['actif'] ?? true,
      atelier: json['id_atelier'] != null
          ? AtelierInfo.fromJson(json['id_atelier'])
          : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get prixFormate => '${prix.toStringAsFixed(0)} FCFA';

  String get genreFormate {
    switch (genre) {
      case 'homme':
        return 'Homme';
      case 'femme':
        return 'Femme';
      case 'unisexe':
        return 'Unisexe';
      default:
        return genre;
    }
  }

  String? get imageUrl {
    if (images.isNotEmpty) {
      return images.first.url;
    }
    return null;
  }
}

class ImageModele {
  final String url;
  final String? alt;

  ImageModele({
    required this.url,
    this.alt,
  });

  factory ImageModele.fromJson(Map<String, dynamic> json) {
    return ImageModele(
      url: json['url'] ?? '',
      alt: json['alt'],
    );
  }
}

class AtelierInfo {
  final String id;
  final String nomAtelier;
  final String? description;

  AtelierInfo({
    required this.id,
    required this.nomAtelier,
    this.description,
  });

  factory AtelierInfo.fromJson(Map<String, dynamic> json) {
    return AtelierInfo(
      id: json['_id'] ?? '',
      nomAtelier: json['nom_atelier'] ?? '',
      description: json['description'],
    );
  }
}
