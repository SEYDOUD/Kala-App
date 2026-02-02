import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur inconnue');
    }
  }
}
