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

  MesureModel? get mesureParDefaut {
    if (_mesures.isEmpty) return null;

    for (final mesure in _mesures) {
      if (mesure.estParDefaut) {
        return mesure;
      }
    }

    return _mesures.first;
  }

  Future<void> loadMesures() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await MesureService.getMesuresByClient();
      final List<dynamic> mesuresData = response['mesures'] ?? [];
      _mesures = mesuresData.map((json) => MesureModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMesure(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await MesureService.createMesure(data);
      await loadMesures();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMesure(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await MesureService.updateMesure(id, data);
      await loadMesures();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
