import 'package:flutter/foundation.dart';
import '../models/tissu_model.dart';
import '../services/tissu_service.dart';

class TissuProvider with ChangeNotifier {
  List<TissuModel> _tissus = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedGenre = 'tous';

  List<TissuModel> get tissus => _tissus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedGenre => _selectedGenre;

  Future<void> loadTissus({String? genre, bool refresh = false}) async {
    if (refresh) _tissus.clear();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await TissuService.getAllTissus(
        genre: genre == 'tous' ? null : genre,
      );

      _tissus = (response['tissus'] as List)
          .map((json) => TissuModel.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setGenre(String genre) async {
    _selectedGenre = genre;
    await loadTissus(genre: genre, refresh: true);
  }
}
