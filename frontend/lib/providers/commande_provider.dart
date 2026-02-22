import 'package:flutter/material.dart';
import '../models/commande_model.dart';
import '../services/commande_service.dart';

class CommandeProvider with ChangeNotifier {
  List<CommandeModel> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommandeModel> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger les commandes du client
  Future<void> loadCommandes() async {
    print('🔄 CommandeProvider: Début du chargement...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await CommandeService.getCommandesByClient();
      print('📦 Response brute: $response');

      final commandesList = response['commandes'] as List;
      print('📋 Nombre de commandes: ${commandesList.length}');

      _commandes =
          commandesList.map((json) => CommandeModel.fromJson(json)).toList();

      print('✅ Commandes chargées: ${_commandes.length}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement commandes: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer une commande par ID
  Future<CommandeModel?> getCommandeById(String id) async {
    try {
      final response = await CommandeService.getCommandeById(id);
      return CommandeModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur récupération commande: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
