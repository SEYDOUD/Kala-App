import 'api_service.dart';
import 'auth_service.dart';

class CommandeService {
  static Future<Map<String, dynamic>> createCommande(
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.post('/commandes', data, token: token);
  }

  static Future<Map<String, dynamic>> processPayment({
    required String commandeId,
    required String modePaiement,
    String? telephone,
    String paymentFlow = 'payment_page',
    String? returnUrl,
    String? cancelUrl,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    final data = {
      'commandeId': commandeId,
      'mode_paiement': modePaiement,
      if (telephone != null) 'telephone': telephone,
      'payment_flow': paymentFlow,
      if (returnUrl != null) 'return_url': returnUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
    };

    return ApiService.post('/commandes/payment', data, token: token);
  }

  static Future<Map<String, dynamic>> getCommandesByClient() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.get('/commandes', token: token);
  }

  static Future<Map<String, dynamic>> getCommandeById(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.get('/commandes/$id', token: token);
  }

  static Future<Map<String, dynamic>> createRetour({
    required String commandeId,
    required String description,
    List<String> photos = const [],
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.post(
      '/commandes/$commandeId/retours',
      {
        'description': description,
        'photos': photos,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> createCommentaire({
    required String commandeId,
    required String texte,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.post(
      '/commandes/$commandeId/commentaires',
      {
        'texte': texte,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> validateSatisfaction({
    required String commandeId,
    bool satisfait = true,
    String? commentaire,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    return ApiService.patch(
      '/commandes/$commandeId/satisfaction',
      {
        'satisfait': satisfait,
        if (commentaire != null && commentaire.trim().isNotEmpty)
          'commentaire': commentaire.trim(),
      },
      token: token,
    );
  }
}
