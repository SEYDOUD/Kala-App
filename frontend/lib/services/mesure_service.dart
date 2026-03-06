import 'api_service.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class MesureService {
  // Recuperer toutes les mesures du client
  static Future<Map<String, dynamic>> getMesuresByClient() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.get('/mesures', token: token);
  }

  // Recuperer une mesure par ID
  static Future<Map<String, dynamic>> getMesureById(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.get('/mesures/$id', token: token);
  }

  // Creer une nouvelle mesure
  static Future<Map<String, dynamic>> createMesure(
      Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.post('/mesures', data, token: token);
  }

  // Mettre a jour une mesure
  static Future<Map<String, dynamic>> updateMesure(
      String id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.put('/mesures/$id', data, token: token);
  }

  // Supprimer une mesure
  static Future<Map<String, dynamic>> deleteMesure(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.delete('/mesures/$id', token: token);
  }

  // Definir une mesure comme par defaut
  static Future<Map<String, dynamic>> setMesureParDefaut(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return await ApiService.patch('/mesures/$id/defaut', {}, token: token);
  }

  // Demarrer une session de vision guidee
  static Future<Map<String, dynamic>> startVisionSession(
      Map<String, dynamic> data) async {
    return await ApiService.post(
      '/vision/session/start',
      data,
      timeout: AppConfig.visionApiTimeout,
    );
  }

  // Analyser une frame/image pour la session de vision
  static Future<Map<String, dynamic>> analyzeVisionFrame(
    String sessionId,
    String imageBase64,
    {bool confirmCapture = false}
  ) async {
    return await ApiService.post(
      '/vision/session/$sessionId/analyze',
      {
        'image_base64': imageBase64,
        'confirm_capture': confirmCapture,
      },
      timeout: AppConfig.visionApiTimeout,
    );
  }

  // Recuperer l'etat d'une session vision
  static Future<Map<String, dynamic>> getVisionSession(String sessionId) async {
    return await ApiService.get(
      '/vision/session/$sessionId',
      timeout: AppConfig.visionApiTimeout,
    );
  }
}
