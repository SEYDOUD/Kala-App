import 'dart:convert';
import 'package:web/web.dart' as web;

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _userTypeKey = 'user_type';

  // Obtenir le localStorage
  static web.Storage get _localStorage => web.window.localStorage;

  // Sauvegarder une valeur
  static Future<void> setString(String key, String value) async {
    _localStorage.setItem(key, value);
  }

  // Récupérer une valeur
  static Future<String?> getString(String key) async {
    return _localStorage.getItem(key);
  }

  // Supprimer une valeur
  static Future<void> remove(String key) async {
    _localStorage.removeItem(key);
  }

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    await setString(_tokenKey, token);
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    return await getString(_tokenKey);
  }

  // Sauvegarder les données utilisateur
  static Future<void> saveUser(
      Map<String, dynamic> user, String userType) async {
    await setString(_userKey, jsonEncode(user));
    await setString(_userTypeKey, userType);
  }

  // Récupérer les données utilisateur
  static Future<Map<String, dynamic>?> getUser() async {
    final userData = await getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Récupérer le type d'utilisateur
  static Future<String?> getUserType() async {
    return await getString(_userTypeKey);
  }

  // Tout supprimer (déconnexion)
  static Future<void> clearAll() async {
    await remove(_tokenKey);
    await remove(_userKey);
    await remove(_userTypeKey);
  }
}
