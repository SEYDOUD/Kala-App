import 'api_service.dart';
import 'auth_service.dart';

class MesureService {
  // Récupérer toutes les mesures du client
  static Future<Map<String, dynamic>> getMesuresByClient() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.get('/mesures', token: token);
  }

  // Récupérer une mesure par ID
  static Future<Map<String, dynamic>> getMesureById(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.get('/mesures/$id', token: token);
  }

  // Créer une nouvelle mesure
  static Future<Map<String, dynamic>> createMesure(
      Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.post('/mesures', data, token: token);
  }

  // Mettre à jour une mesure
  static Future<Map<String, dynamic>> updateMesure(
      String id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.put('/mesures/$id', data, token: token);
  }

  // Supprimer une mesure
  static Future<Map<String, dynamic>> deleteMesure(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.delete('/mesures/$id', token: token);
  }

  // Définir une mesure comme par défaut
  static Future<Map<String, dynamic>> setMesureParDefaut(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.patch('/mesures/$id/defaut', {}, token: token);
  }
}
