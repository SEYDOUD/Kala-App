import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Initialiser (vérifier si déjà connecté)
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        _user = await AuthService.getUser();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Inscription Client
  Future<bool> registerClient({
    required String prenom,
    required String nom,
    required String username,
    required String password,
    required String email,
    required String telephone,
    String? adresse,
    DateTime? dateNaissance,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.registerClient(
        prenom: prenom,
        nom: nom,
        username: username,
        password: password,
        email: email,
        telephone: telephone,
        adresse: adresse,
        dateNaissance: dateNaissance,
      );

      final token = response['token'];
      final userType = response['userType'];
      _user = UserModel.fromJson(response['user'], userType);

      await AuthService.saveAuthData(token: token, user: _user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Inscription Prestataire
  Future<bool> registerPrestataire({
    required String username,
    required String password,
    required String email,
    required String telephone,
    required String nomAtelier, // ← AJOUT
    String? description, // ← AJOUT
    String? adresse, // ← AJOUT
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.registerPrestataire(
        username: username,
        password: password,
        email: email,
        telephone: telephone,
        nomAtelier: nomAtelier, // ← AJOUT
        description: description, // ← AJOUT
        adresse: adresse, // ← AJOUT
      );

      final token = response['token'];
      final userType = response['userType'];
      _user = UserModel.fromJson(response['user'], userType);

      final atelier = response['atelier']; // ← AJOUT

      await AuthService.saveAuthData(
        token: token,
        user: _user!,
        atelier: atelier, // ← AJOUT
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        username: username,
        password: password,
      );

      final token = response['token'];
      final userType = response['userType'];
      _user = UserModel.fromJson(response['user'], userType);

      await AuthService.saveAuthData(token: token, user: _user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  // Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
