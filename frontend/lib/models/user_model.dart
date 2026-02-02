class UserModel {
  final String id;
  final String username;
  final String email;
  final String? prenom;
  final String? nom;
  final String? telephone;
  final String? adresse;
  final DateTime? dateNaissance;
  final String userType; // 'client', 'prestataire', 'admin'

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.prenom,
    this.nom,
    this.telephone,
    this.adresse,
    this.dateNaissance,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String userType) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      prenom: json['prenom'],
      nom: json['nom'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'])
          : null,
      userType: userType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
      'date_naissance': dateNaissance?.toIso8601String(),
      'userType': userType,
    };
  }

  String get fullName {
    if (prenom != null && nom != null) {
      return '$prenom $nom';
    }
    return username;
  }
}
