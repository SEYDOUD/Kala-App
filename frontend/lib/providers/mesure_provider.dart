import 'package:flutter/foundation.dart';
import '../models/mesure_model.dart';
import '../services/mesure_service.dart';

class MesureProvider with ChangeNotifier {
  List<MesureModel> _mesures = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MesureModel> get mesures => _mesures;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MesureModel? get mesureParDefaut => _mesures.firstWhere((m) => m.estParDefaut,
      orElse: () => _mesures.isNotEmpty ? _mesures.first : null as MesureModel);

  // Charger toutes les mesures
  Future<void> loadMesures() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await MesureService.getMesuresByClient();
      final List<dynamic> mesuresData = response['mesures'] ?? [];
      _mesures = mesuresData.map((json) => MesureModel.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer une nouvelle mesure
  Future<bool> createMesure(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await MesureService.createMesure(data);
      await loadMesures(); // Recharger la liste
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

  // Mettre à jour une mesure
  Future<bool> updateMesure(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await MesureService.updateMesure(id, data);
      await loadMesures();
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

  // Supprimer une mesure
  Future<bool> deleteMesure(String id) async {
    try {
      await MesureService.deleteMesure(id);
      await loadMesures();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Définir une mesure par défaut
  Future<bool> setMesureParDefaut(String id) async {
    try {
      await MesureService.setMesureParDefaut(id);
      await loadMesures();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
