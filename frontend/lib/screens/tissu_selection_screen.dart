import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tissu_provider.dart';
import '../providers/panier_provider.dart';
import '../models/tissu_model.dart';

class TissuSelectionScreen extends StatefulWidget {
  final int panierItemIndex;

  const TissuSelectionScreen({
    Key? key,
    required this.panierItemIndex,
  }) : super(key: key);

  @override
  State<TissuSelectionScreen> createState() => _TissuSelectionScreenState();
}

class _TissuSelectionScreenState extends State<TissuSelectionScreen> {
  double _metrage = 0;
  TissuModel? _tissuEnCours; // Le tissu actuellement sélectionné avant valider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TissuProvider>(context, listen: false)
          .loadTissus(genre: 'tous', refresh: true);
    });
  }

  // Vérifier si un tissu est déjà validé dans le panier
  bool _isTissuValide(TissuModel tissu, PanierProvider panierProvider) {
    final item = panierProvider.items[widget.panierItemIndex];
    return item.tissusChoisis.any((tp) => tp.tissu.id == tissu.id);
  }

  // Sélectionner un tissu (avant validation)
  void _selectTissu(TissuModel tissu, PanierProvider panierProvider) {
    // Si c'est un tissu déjà validé, on ne peut pas le re-sélectionner
    if (_isTissuValide(tissu, panierProvider)) return;

    setState(() {
      _tissuEnCours = tissu;
      _metrage = 0;
    });
  }

  // Valider le tissu en cours avec le métrage
  void _validerTissu(PanierProvider panierProvider) {
    if (_tissuEnCours == null || _metrage <= 0) return;

    panierProvider.addTissuToItem(
      widget.panierItemIndex,
      TissuPanier(tissu: _tissuEnCours!, metrage: _metrage),
    );

    // Reset
    setState(() {
      _tissuEnCours = null;
      _metrage = 0;
    });
  }

  // Supprimer un tissu déjà validé
  void _supprimerTissu(String tissuId, PanierProvider panierProvider) {
    panierProvider.removeTissuFromItem(widget.panierItemIndex, tissuId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TissuProvider, PanierProvider>(
      builder: (context, tissuProvider, panierProvider, child) {
        final item = panierProvider.items[widget.panierItemIndex];
        final tissusValides = item.tissusChoisis;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Choisir des tissus'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // ─── Tissus déjà validés (horizontal scroll) ───────
              if (tissusValides.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tissus sélectionnés',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 85,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tissusValides.length,
                          itemBuilder: (context, index) {
                            final tp = tissusValides[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 75,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFFFA500), width: 2),
                              ),
                              child: Stack(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: tp.tissu.imageUrl != null
                                        ? Image.network(
                                            tp.tissu.imageUrl!,
                                            width: 75,
                                            height: 85,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.check),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.check),
                                          ),
                                  ),
                                  // Métrage badge
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                      child: Text(
                                        '${tp.metrage.toInt()}m',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bouton supprimer (X)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _supprimerTissu(
                                          tp.tissu.id, panierProvider),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.85),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Filtres genre ────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildGenreFilter('Tous', 'tous', tissuProvider),
                    const SizedBox(width: 8),
                    _buildGenreFilter('Homme', 'homme', tissuProvider),
                    const SizedBox(width: 8),
                    _buildGenreFilter('Femme', 'femme', tissuProvider),
                    const SizedBox(width: 8),
                    _buildGenreFilter('Unisex', 'unisexe', tissuProvider),
                  ],
                ),
              ),

              // ─── Grille tissus ────────────────────────────────
              Expanded(
                child: tissuProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: tissuProvider.tissus.length,
                        itemBuilder: (context, index) {
                          final tissu = tissuProvider.tissus[index];
                          final isValide =
                              _isTissuValide(tissu, panierProvider);
                          final isEnCours = _tissuEnCours?.id == tissu.id;

                          return GestureDetector(
                            onTap: () {
                              if (!isValide) {
                                _selectTissu(tissu, panierProvider);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isValide
                                      ? Colors.green
                                      : isEnCours
                                          ? const Color(0xFFFFA500)
                                          : Colors.grey[300]!,
                                  width: (isValide || isEnCours) ? 3 : 1,
                                ),
                                color: isValide
                                    ? Colors.green.withOpacity(0.05)
                                    : isEnCours
                                        ? const Color(0xFFFFA500)
                                            .withOpacity(0.05)
                                        : Colors.white,
                              ),
                              child: Column(
                                children: [
                                  // Image
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: tissu.imageUrl != null
                                              ? Image.network(
                                                  tissu.imageUrl!,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      Container(
                                                    color: Colors.grey[300],
                                                    child:
                                                        const Icon(Icons.check),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child:
                                                      const Icon(Icons.check),
                                                ),
                                        ),
                                        // Prix overlay
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            child: Text(
                                              tissu.prixFormate,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Badge validé ✓
                                        if (isValide)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Nom
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      tissu.nom,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isEnCours
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isValide
                                            ? Colors.green
                                            : isEnCours
                                                ? const Color(0xFFFFA500)
                                                : Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ─── Bottom bar : métrage + Valider OU bouton Retour ──
              Container(
                padding: const EdgeInsets.all(16),
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
                child: _tissuEnCours != null
                    // ── Un tissu est sélectionné → montrer métrage + Valider
                    ? Column(
                        children: [
                          // Nom du tissu en cours
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _tissuEnCours!.nom,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFA500),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tissuEnCours = null;
                                    _metrage = 0;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Sélecteur métrage
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
                                        if (_metrage > 0) {
                                          setState(() {
                                            _metrage--;
                                          });
                                        }
                                      },
                                    ),
                                    Text(
                                      '${_metrage.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          _metrage++;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'mètres',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Bouton Valider ce tissu
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _metrage > 0
                                      ? () => _validerTissu(panierProvider)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: const Text('Valider'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    // ── Aucun tissu en cours → bouton Terminer
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tissusValides.isNotEmpty
                                ? const Color(0xFFFFA500)
                                : Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            tissusValides.isNotEmpty
                                ? 'Terminer (${tissusValides.length} tissu${tissusValides.length > 1 ? 's' : ''})'
                                : 'Retour',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenreFilter(String label, String value, TissuProvider provider) {
    final isSelected = provider.selectedGenre == value;

    return InkWell(
      onTap: () => provider.setGenre(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA500) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'homme'
                  ? Icons.man
                  : value == 'femme'
                      ? Icons.woman
                      : Icons.people,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
