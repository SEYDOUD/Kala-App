import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/modele_model.dart';
import '../services/modele_service.dart';
import '../providers/panier_provider.dart';
import 'tissu_selection_screen.dart';
import 'mesure_informations_screen.dart';

class ModeleDetailScreen extends StatefulWidget {
  final String modeleId;

  const ModeleDetailScreen({
    Key? key,
    required this.modeleId,
  }) : super(key: key);

  @override
  State<ModeleDetailScreen> createState() => _ModeleDetailScreenState();
}

class _ModeleDetailScreenState extends State<ModeleDetailScreen> {
  ModeleModel? _modele;
  bool _isLoading = true;
  String? _errorMessage;
  int _quantite = 1;
  int? _panierItemIndex;

  @override
  void initState() {
    super.initState();
    _loadModele();
  }

  Future<void> _loadModele() async {
    try {
      final response = await ModeleService.getModeleById(widget.modeleId);
      setState(() {
        _modele = ModeleModel.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openTissuSelection() {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);

    if (_panierItemIndex == null) {
      final newItem = ItemPanier(
        modele: _modele!,
        quantite: _quantite,
      );
      panierProvider.addItem(newItem);
      setState(() {
        _panierItemIndex = panierProvider.items.length - 1;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TissuSelectionScreen(panierItemIndex: _panierItemIndex!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _modele == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails')),
        body: Center(child: Text(_errorMessage ?? 'Modèle non trouvé')),
      );
    }

    final panierProvider = Provider.of<PanierProvider>(context);
    final tissusChoisis = _panierItemIndex != null &&
            _panierItemIndex! < panierProvider.items.length
        ? panierProvider.items[_panierItemIndex!].tissusChoisis
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            automaticallyImplyLeading: false, // on gère le retour nous-même
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // ── Image principale ────────────────────────────
                  _modele!.imageUrl != null
                      ? Image.network(
                          _modele!.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.checkroom,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),

                  // ── Icones en haut dans cercles blancs ──────────
                  Positioned(
                    top: 50, // juste sous la status bar
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton retour
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.black,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Favoris + Share
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.favorite_border),
                                color: Colors.black,
                                onPressed: () {
                                  // TODO: Ajouter aux favoris
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined),
                                color: Colors.black,
                                onPressed: () {
                                  // TODO: Panier
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Tissus miniatures en bas à droite ───────────
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _openTissuSelection,
                      child: Row(
                        children: [
                          // Miniatures tissus choisis
                          ...tissusChoisis.map((tp) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 60,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: tp.tissu.imageUrl != null
                                        ? Image.network(
                                            tp.tissu.imageUrl!,
                                            width: 60,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                              color: Colors.grey[300],
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                          ),
                                  ),
                                  // Prix badge
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          bottom: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        tp.tissu.prixFormate,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // ── Bouton "+" : apparaît SEULEMENT si aucun tissu ──
                          if (tissusChoisis.isEmpty)
                            Container(
                              width: 52,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey[400]!, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  color: Color(0xFFFFA500),
                                  size: 26,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu détails (identique avant) ─────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < _modele!.noteMoyenne.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 20,
                          color: const Color(0xFFFFA500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_modele!.noteMoyenne.toStringAsFixed(1)} (${_modele!.nombreAvis} avis)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nom
                  Text(
                    _modele!.nom,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Prix
                  Text(
                    _modele!.prixFormate,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA500),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Genre + Durée
                  _buildInfoRow('Genre', _modele!.genreFormate),
                  const SizedBox(height: 12),
                  _buildInfoRow('Durée de conception',
                      '${_modele!.dureeConception} jours'),
                  const SizedBox(height: 24),

                  // Atelier
                  if (_modele!.atelier != null) ...[
                    const Text(
                      'Atelier',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFA500),
                          child: Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(_modele!.atelier!.nomAtelier),
                        subtitle: _modele!.atelier!.description != null
                            ? Text(_modele!.atelier!.description!)
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Voir l'atelier
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (_modele!.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _modele!.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar : quantité + Commander ──────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_quantite > 1) {
                        setState(() {
                          _quantite--;
                        });
                      }
                    },
                  ),
                  Text(
                    '$_quantite',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _quantite++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Aller à la prise de mesures
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MesureInformationsScreen(
                        panierItemIndex: _panierItemIndex ?? 0,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Commander'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
