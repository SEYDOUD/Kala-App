import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class UploadService {
  static Future<String> uploadSingleXFile(XFile file) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    final uri = Uri.parse('${AppConfig.apiUrl}/upload/single');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: file.name,
      ),
    );

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(AppConfig.apiTimeout);
    } on TimeoutException {
      throw Exception('Timeout upload: la requete a pris trop de temps');
    }

    final rawBody = await streamedResponse.stream.bytesToString();
    Map<String, dynamic> body;
    try {
      body = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      body = {'error': 'Reponse upload invalide'};
    }

    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      final imageData = body['image'];
      if (imageData is Map<String, dynamic>) {
        final url = imageData['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          return url;
        }
      }
      throw Exception('URL image manquante dans la reponse upload');
    }

    throw Exception(body['error']?.toString() ?? 'Erreur upload image');
  }
}
