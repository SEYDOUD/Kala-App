class MesureModel {
  final String id;
  final String idClient;
  final String nomMesure;
  final String genre;
  final double tailleCm;
  final double poidsKg;
  final int age;
  final double? tourDeTete;
  final double? epaule;
  final double? dos;
  final double? ventre;
  final double? abdomen;
  final double? cuisse;
  final double? entreJambe;
  final double? entrePied;
  final double? poitrine;
  final String typePrise;
  final String? photoUrl;
  final bool estParDefaut;
  final DateTime createdAt;

  MesureModel({
    required this.id,
    required this.idClient,
    required this.nomMesure,
    required this.genre,
    required this.tailleCm,
    required this.poidsKg,
    required this.age,
    this.tourDeTete,
    this.epaule,
    this.dos,
    this.ventre,
    this.abdomen,
    this.cuisse,
    this.entreJambe,
    this.entrePied,
    this.poitrine,
    required this.typePrise,
    this.photoUrl,
    required this.estParDefaut,
    required this.createdAt,
  });

  factory MesureModel.fromJson(Map<String, dynamic> json) {
    return MesureModel(
      id: json['_id'] ?? '',
      idClient: json['id_client'] ?? '',
      nomMesure: json['nom_mesure'] ?? '',
      genre: json['genre'] ?? '',
      tailleCm: (json['taille_cm'] ?? 0).toDouble(),
      poidsKg: (json['poids_kg'] ?? 0).toDouble(),
      age: json['age'] ?? 0,
      tourDeTete: json['tour_de_tete']?.toDouble(),
      epaule: json['epaule']?.toDouble(),
      dos: json['dos']?.toDouble(),
      ventre: json['ventre']?.toDouble(),
      abdomen: json['abdomen']?.toDouble(),
      cuisse: json['cuisse']?.toDouble(),
      entreJambe: json['entre_jambe']?.toDouble(),
      entrePied: json['entre_pied']?.toDouble(),
      poitrine: json['poitrine']?.toDouble(),
      typePrise: json['type_prise'] ?? 'manuel',
      photoUrl: json['photo_url'],
      estParDefaut: json['est_par_defaut'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_mesure': nomMesure,
      'genre': genre,
      'taille_cm': tailleCm,
      'poids_kg': poidsKg,
      'age': age,
      if (tourDeTete != null) 'tour_de_tete': tourDeTete,
      if (epaule != null) 'epaule': epaule,
      if (dos != null) 'dos': dos,
      if (ventre != null) 'ventre': ventre,
      if (abdomen != null) 'abdomen': abdomen,
      if (cuisse != null) 'cuisse': cuisse,
      if (entreJambe != null) 'entre_jambe': entreJambe,
      if (entrePied != null) 'entre_pied': entrePied,
      if (poitrine != null) 'poitrine': poitrine,
      'type_prise': typePrise,
      if (photoUrl != null) 'photo_url': photoUrl,
      'est_par_defaut': estParDefaut,
    };
  }
}
