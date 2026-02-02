import 'package:flutter/foundation.dart';
import '../models/modele_model.dart';
import '../services/modele_service.dart';

class ModeleProvider with ChangeNotifier {
  List<ModeleModel> _modeles = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedGenre = 'tous'; // 'tous', 'homme', 'femme'
  String _searchQuery = '';

  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;

  List<ModeleModel> get modeles => _modeles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedGenre => _selectedGenre;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get total => _total;
  bool get hasMore => _currentPage < _totalPages;

  // Charger les modèles
  Future<void> loadModeles({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _modeles.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ModeleService.getAllModeles(
        page: _currentPage,
        limit: 10,
        genre: _selectedGenre == 'tous' ? null : _selectedGenre,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final List<dynamic> modelesData = response['modeles'] ?? [];
      final newModeles =
          modelesData.map((json) => ModeleModel.fromJson(json)).toList();

      if (refresh) {
        _modeles = newModeles;
      } else {
        _modeles.addAll(newModeles);
      }

      _totalPages = response['totalPages'] ?? 1;
      _total = response['total'] ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger la page suivante
  Future<void> loadMore() async {
    if (!_isLoading && hasMore) {
      _currentPage++;
      await loadModeles();
    }
  }

  // Changer le filtre de genre
  Future<void> setGenre(String genre) async {
    if (_selectedGenre != genre) {
      _selectedGenre = genre;
      await loadModeles(refresh: true);
    }
  }

  // Rechercher
  Future<void> search(String query) async {
    _searchQuery = query;
    await loadModeles(refresh: true);
  }

  // Rafraîchir
  Future<void> refresh() async {
    await loadModeles(refresh: true);
  }

  // Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
