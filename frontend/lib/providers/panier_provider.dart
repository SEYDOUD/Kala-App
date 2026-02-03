import 'package:flutter/foundation.dart';
import '../models/modele_model.dart';
import '../models/tissu_model.dart';

// Représente un tissu dans le panier avec sa quantité de mètres
class TissuPanier {
  final TissuModel tissu;
  double metrage;

  TissuPanier({
    required this.tissu,
    this.metrage = 1,
  });

  double get sousTotal => tissu.prix * metrage;
}

// Représente un item complet dans le panier (modèle + tissus choisis + quantité)
class ItemPanier {
  final ModeleModel modele;
  List<TissuPanier> tissusChoisis;
  int quantite;

  ItemPanier({
    required this.modele,
    List<TissuPanier>? tissusChoisis,
    this.quantite = 1,
  }) : tissusChoisis = tissusChoisis ?? [];

  double get prix => modele.prix;

  double get totalTissus =>
      tissusChoisis.fold(0.0, (sum, tp) => sum + tp.sousTotal);

  double get sousTotal => (prix + totalTissus) * quantite;
}

class PanierProvider with ChangeNotifier {
  final List<ItemPanier> _items = [];

  List<ItemPanier> get items => _items;
  int get nombreItems => _items.length;

  double get total => _items.fold(0.0, (sum, item) => sum + item.sousTotal);

  bool get isEmpty => _items.isEmpty;

  // Ajouter un item au panier
  void addItem(ItemPanier item) {
    _items.add(item);
    notifyListeners();
  }

  // Supprimer un item du panier
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // Mettre à jour la quantité d'un item
  void updateQuantite(int index, int quantite) {
    if (index >= 0 && index < _items.length) {
      if (quantite <= 0) {
        removeItem(index);
      } else {
        _items[index].quantite = quantite;
        notifyListeners();
      }
    }
  }

  // Ajouter un tissu à un item
  void addTissuToItem(int itemIndex, TissuPanier tissuPanier) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      // Vérifier si le tissu existe déjà
      final existingIndex = _items[itemIndex]
          .tissusChoisis
          .indexWhere((tp) => tp.tissu.id == tissuPanier.tissu.id);

      if (existingIndex >= 0) {
        // Mettre à jour le métrage
        _items[itemIndex].tissusChoisis[existingIndex].metrage =
            tissuPanier.metrage;
      } else {
        _items[itemIndex].tissusChoisis.add(tissuPanier);
      }
      notifyListeners();
    }
  }

  // Supprimer un tissu d'un item
  void removeTissuFromItem(int itemIndex, String tissuId) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      _items[itemIndex]
          .tissusChoisis
          .removeWhere((tp) => tp.tissu.id == tissuId);
      notifyListeners();
    }
  }

  // Mettre à jour le métrage d'un tissu
  void updateMetrage(int itemIndex, String tissuId, double metrage) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final tissuIndex = _items[itemIndex]
          .tissusChoisis
          .indexWhere((tp) => tp.tissu.id == tissuId);

      if (tissuIndex >= 0) {
        if (metrage <= 0) {
          removeTissuFromItem(itemIndex, tissuId);
        } else {
          _items[itemIndex].tissusChoisis[tissuIndex].metrage = metrage;
        }
        notifyListeners();
      }
    }
  }

  // Vider le panier
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
