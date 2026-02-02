import '../config/app_config.dart';
import '../models/modele_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ModeleService {
  // Récupérer tous les modèles
  static Future<Map<String, dynamic>> getAllModeles({
    int page = 1,
    int limit = 10,
    String? genre,
    String? search,
  }) async {
    String endpoint = '/modeles?page=$page&limit=$limit';

    if (genre != null) {
      endpoint += '&genre=$genre';
    }

    if (search != null && search.isNotEmpty) {
      endpoint += '&search=$search';
    }

    return await ApiService.get(endpoint);
  }

  // Récupérer un modèle par ID
  static Future<Map<String, dynamic>> getModeleById(String id) async {
    return await ApiService.get('/modeles/$id');
  }

  // Créer un modèle (prestataire uniquement)
  static Future<Map<String, dynamic>> createModele({
    required String nom,
    required String genre,
    required double prix,
    String? description,
    int? dureeConception,
    List<Map<String, String>>? images,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    final data = {
      'nom': nom,
      'genre': genre,
      'prix': prix,
      if (description != null) 'description': description,
      if (dureeConception != null) 'duree_conception': dureeConception,
      if (images != null) 'images': images,
    };

    return await ApiService.post('/modeles', data, token: token);
  }

  // Récupérer les modèles par atelier
  static Future<Map<String, dynamic>> getModelesByAtelier(
      String atelierId) async {
    return await ApiService.get('/modeles/atelier/$atelierId');
  }
}
