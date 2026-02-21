import 'dart:convert';
// import 'dart:convert'; // ← AJOUTEZ CETTE LIGNE
// import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  // Inscription Client
  static Future<Map<String, dynamic>> registerClient({
    required String prenom,
    required String nom,
    required String username,
    required String password,
    required String email,
    required String telephone,
    String? adresse,
    DateTime? dateNaissance,
  }) async {
    final data = {
      'prenom': prenom,
      'nom': nom,
      'username': username,
      'password': password,
      'email': email,
      'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
      if (dateNaissance != null)
        'date_naissance': dateNaissance.toIso8601String(),
    };

    return await ApiService.post('/auth/register/client', data);
  }

  // Inscription Prestataire + Atelier (MODIFIÉ)
  static Future<Map<String, dynamic>> registerPrestataire({
    required String username,
    required String password,
    required String email,
    required String telephone,
    required String nomAtelier, // ← AJOUT
    String? description, // ← AJOUT
    String? adresse, // ← AJOUT
  }) async {
    final data = {
      'username': username,
      'password': password,
      'email': email,
      'telephone': telephone,
      'nom_atelier': nomAtelier, // ← AJOUT
      if (description != null) 'description': description,
      if (adresse != null) 'adresse': adresse,
    };

    return await ApiService.post('/auth/register/prestataire', data);
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final data = {
      'username': username,
      'password': password,
    };

    return await ApiService.post('/auth/login', data);
  }

  // Sauvegarder les données de connexion
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> user,
    String? userType,
    Map<String, dynamic>? atelier,
  }) async {
    await StorageService.saveToken(token);
    await StorageService.saveUser(jsonEncode(user)); // ← CONVERTIR EN STRING

    if (userType != null) {
      await StorageService.saveUserType(userType);
    }

    if (atelier != null) {
      await StorageService.saveAtelier(
          jsonEncode(atelier)); // ← CONVERTIR EN STRING
    }
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  // Récupérer l'utilisateur
  static Future<UserModel?> getUser() async {
    final userData = await StorageService.getUser();
    final userType = await StorageService.getUserType();

    if (userData == null || userType == null) return null;

    final Map<String, dynamic> userMap = jsonDecode(userData);
    return UserModel.fromJson(userMap, userType);
  }

  // Récupérer l'atelier
  static Future<Map<String, dynamic>?> getAtelier() async {
    final atelierData = await StorageService.getAtelier();
    if (atelierData == null) return null;
    return jsonDecode(atelierData); // ← DÉCODER LE JSON
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Déconnexion
  static Future<void> logout() async {
    await StorageService.clearAll();
    await StorageService.remove('atelier_data');
  }

  // Obtenir le profil
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }
    return await ApiService.get('/auth/profile', token: token);
  }

  // Modifier le mot de passe
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    final data = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };

    return await ApiService.put('/auth/change-password', data, token: token);
  }
}
