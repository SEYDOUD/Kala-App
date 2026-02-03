class TissuModel {
  final String id;
  final String nom;
  final String? description;
  final String genre;
  final double prix;
  final String? couleur;
  final String? typeMetrage;
  final double baseMetrage;
  final List<ImageTissu> images;

  TissuModel({
    required this.id,
    required this.nom,
    this.description,
    required this.genre,
    required this.prix,
    this.couleur,
    this.typeMetrage,
    required this.baseMetrage,
    required this.images,
  });

  factory TissuModel.fromJson(Map<String, dynamic> json) {
    return TissuModel(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      genre: json['genre'] ?? 'unisexe',
      prix: (json['prix'] ?? 0).toDouble(),
      couleur: json['couleur'],
      typeMetrage: json['type_metrage'],
      baseMetrage: (json['base_metrage'] ?? 1).toDouble(),
      images: (json['images'] as List? ?? [])
          .map((img) => ImageTissu.fromJson(img))
          .toList(),
    );
  }

  String get prixFormate => '${prix.toStringAsFixed(0)}f/m';
  String? get imageUrl => images.isNotEmpty ? images.first.url : null;
}

class ImageTissu {
  final String url;
  final String? alt;

  ImageTissu({required this.url, this.alt});

  factory ImageTissu.fromJson(Map<String, dynamic> json) {
    return ImageTissu(url: json['url'] ?? '', alt: json['alt']);
  }
}
