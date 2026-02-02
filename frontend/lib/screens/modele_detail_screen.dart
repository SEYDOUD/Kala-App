import 'package:flutter/material.dart';
import '../models/modele_model.dart';
import '../services/modele_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _modele == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails'),
        ),
        body: Center(
          child: Text(_errorMessage ?? 'Modèle non trouvé'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _modele!.imageUrl != null
                  ? Image.network(
                      _modele!.imageUrl!,
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
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // TODO: Ajouter aux favoris
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Partager
                },
              ),
            ],
          ),

          // Contenu
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

                  // Informations
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

      // Bouton Commander
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
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Prendre mesures
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFFA500),
                  side: const BorderSide(color: Color(0xFFFFA500)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Prendre mesures'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Commander
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
