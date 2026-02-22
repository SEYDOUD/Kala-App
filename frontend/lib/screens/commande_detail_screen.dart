import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/commande_provider.dart';
import '../models/commande_model.dart';

class CommandeDetailScreen extends StatefulWidget {
  final String commandeId;

  const CommandeDetailScreen({
    Key? key,
    required this.commandeId,
  }) : super(key: key);

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  CommandeModel? _commande;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommande();
  }

  Future<void> _loadCommande() async {
    final commandeProvider =
        Provider.of<CommandeProvider>(context, listen: false);
    final commande = await commandeProvider.getCommandeById(widget.commandeId);
    setState(() {
      _commande = commande;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF3E2723),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3E2723),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFA500)),
        ),
      );
    }

    if (_commande == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF3E2723),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3E2723),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'Commande non trouvée',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: const Text('Suivi de la Commande'),
        backgroundColor: const Color(0xFF3E2723),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          // Timeline de statut
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF3E2723),
            child: _buildTimeline(_commande!.statut),
          ),

          // Détails de la commande
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Numéro de Commande', _commande!.numeroCommande),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date de Commande',
                      '${_commande!.createdAt.day}/${_commande!.createdAt.month}/${_commande!.createdAt.year}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Date de Livraison', '13/01/2026'),
                    const SizedBox(height: 24),

                    // Note de commande
                    if (_commande!.items.isNotEmpty &&
                        _commande!.items[0].note != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Note de Commande',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[100],
                            child: Text(
                              _commande!.items[0].note!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Articles
                    if (_commande!.items.isNotEmpty) ...[
                      ..._commande!.items
                          .map((item) => _buildArticleCard(item)),
                      const SizedBox(height: 24),
                    ],

                    // Récapitulatif
                    _buildRecapitulatif(_commande!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String statut) {
    final steps = [
      {'label': 'Validée', 'value': 'confirmee'},
      {'label': 'Commande en Tissus', 'value': 'en_cours'},
      {'label': 'Chez le Tailleur', 'value': 'en_cours'},
      {'label': 'Repassage', 'value': 'prete'},
      {'label': 'Livraison', 'value': 'livree'},
    ];

    final currentIndex = _getStatusIndex(statut);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index <= currentIndex;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Numéro / Check
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFFFA500)
                            : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Ligne de connexion
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? const Color(0xFFFFA500)
                              : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index]['label']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _getStatusIndex(String statut) {
    switch (statut) {
      case 'en_attente':
        return -1;
      case 'confirmee':
        return 0;
      case 'en_cours':
        return 2;
      case 'prete':
        return 3;
      case 'livree':
        return 4;
      default:
        return -1;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(CommandeItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Image
              Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.checkroom),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: const Color(0xFFFFA500),
                      child: const Text(
                        'Chez Kala',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Costume Diomaye 3 pièces',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildArticleDetailRow('Quantité', 'x${item.quantite}'),
          _buildArticleDetailRow(
            'Tissu',
            '${item.tissus.fold<double>(0, (sum, t) => sum + t.metrage)}m',
          ),
          _buildArticleDetailRow(
              'Modèle', '${item.prixUnitaire.toStringAsFixed(0)} F'),
          _buildArticleDetailRow('Frais de Service', '2 000 F'),
          _buildArticleDetailRow('Livraison', '1 500 F'),
          const Divider(height: 20),
          _buildArticleDetailRow(
              'Total', '${item.sousTotal.toStringAsFixed(0)} F',
              isBold: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mesure : Seydou',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  'Modifier',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFA500),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleDetailRow(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isBold ? Colors.black : Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapitulatif(CommandeModel commande) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${commande.montantTotal.toStringAsFixed(0)} F',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
