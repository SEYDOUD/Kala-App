import 'api_service.dart';
import 'auth_service.dart';

class CommandeService {
  // Créer une commande
  static Future<Map<String, dynamic>> createCommande(
      Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.post('/commandes', data, token: token);
  }

  // Traiter le paiement
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
      throw Exception('Non authentifié');
    }

    final data = {
      'commandeId': commandeId,
      'mode_paiement': modePaiement,
      if (telephone != null) 'telephone': telephone,
      'payment_flow': paymentFlow,
      if (returnUrl != null) 'return_url': returnUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
    };

    return await ApiService.post('/commandes/payment', data, token: token);
  }

  // Récupérer les commandes du client
  static Future<Map<String, dynamic>> getCommandesByClient() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    print('🔍 Fetching commandes with token: ${token.substring(0, 20)}...');
    final response = await ApiService.get('/commandes', token: token);
    print('📦 Commandes reçues: $response');
    return response;
  }

  // Récupérer une commande par ID
  static Future<Map<String, dynamic>> getCommandeById(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    return await ApiService.get('/commandes/$id', token: token);
  }
}
