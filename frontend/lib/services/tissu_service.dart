import 'api_service.dart';

class TissuService {
  static Future<Map<String, dynamic>> getAllTissus({
    String? genre,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/tissus?page=$page&limit=$limit';
    if (genre != null) endpoint += '&genre=$genre';
    return await ApiService.get(endpoint);
  }

  static Future<Map<String, dynamic>> getTissuById(String id) async {
    return await ApiService.get('/tissus/$id');
  }
}
