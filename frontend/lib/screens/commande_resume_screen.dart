import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/panier_provider.dart';
import '../providers/mesure_provider.dart';
import '../widgets/note_commande_dialog.dart';
import 'mesure_informations_screen.dart';
import 'mesure_existante_screen.dart';
import '../models/mesure_model.dart';

class CommandeResumeScreen extends StatefulWidget {
  final int panierItemIndex;

  const CommandeResumeScreen({
    Key? key,
    required this.panierItemIndex,
  }) : super(key: key);

  @override
  State<CommandeResumeScreen> createState() => _CommandeResumeScreenState();
}

class _CommandeResumeScreenState extends State<CommandeResumeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les mesures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesureProvider>(context, listen: false).loadMesures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Résumé de la Commande'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Consumer<PanierProvider>(
        builder: (context, panierProvider, child) {
          if (widget.panierItemIndex >= panierProvider.items.length) {
            return const Center(
              child: Text('Article non trouvé'),
            );
          }

          final item = panierProvider.items[widget.panierItemIndex];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note de Commande
                      _buildNoteSection(context, item, panierProvider),
                      const SizedBox(height: 16),

                      // Carte Modèle
                      _buildModeleCard(item),
                      const SizedBox(height: 16),

                      // Carte Détails
                      _buildDetailsCard(item),
                      const SizedBox(height: 16),

                      // Carte Mesure
                      _buildMesureCard(context, item),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom bar
              _buildBottomBar(context, item, panierProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoteSection(
      BuildContext context, ItemPanier item, PanierProvider panierProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Note de Commande',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: const Color(0xFFFFA500),
                onPressed: () {
                  showNoteCommandeDialog(context, widget.panierItemIndex);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.note != null && item.note!.isNotEmpty
                ? item.note!
                : 'Aucune spécification ajoutée',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
              fontStyle: item.note == null || item.note!.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeleCard(ItemPanier item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.modele.imageUrl != null
                ? Image.network(
                    item.modele.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.checkroom),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.checkroom),
                  ),
          ),
          const SizedBox(width: 16),
          // Nom et prix
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.modele.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.modele.prixFormate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFA500),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ItemPanier item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de la commande',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Quantité
          _buildDetailRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Quantité',
            value: 'x${item.quantite}',
          ),
          const SizedBox(height: 12),

          // Tissus
          if (item.tissusChoisis.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.checkroom_outlined,
              label: 'Tissus (${item.tissusChoisis.length})',
              value: '${item.totalTissus.toStringAsFixed(1)}m',
            ),
            const SizedBox(height: 8),
            ...item.tissusChoisis.map((tp) => Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tp.tissu.nom,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        '${tp.metrage}m × ${tp.tissu.prix.toStringAsFixed(0)}F',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // Sous-total modèle
          _buildPriceRow('Modèle', item.modele.prix.toStringAsFixed(0)),
          const SizedBox(height: 8),

          // Sous-total tissus
          if (item.tissusChoisis.isNotEmpty)
            _buildPriceRow('Tissus', item.totalTissus.toStringAsFixed(0),
                isSubtotal: true),

          const SizedBox(height: 8),

          // Frais de service
          _buildPriceRow('Frais de Service', '2 000', isSubtotal: true),

          const SizedBox(height: 12),
          const Divider(thickness: 2),
          const SizedBox(height: 12),

          // Total
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
                '${item.sousTotal.toStringAsFixed(0)} F',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMesureCard(BuildContext context, ItemPanier item) {
    return Consumer<MesureProvider>(
      builder: (context, mesureProvider, child) {
        // Récupérer la mesure depuis l'ID
        MesureModel? mesure;
        if (item.mesureId != null) {
          try {
            mesure = mesureProvider.mesures.firstWhere(
              (m) => m.id == item.mesureId,
            );
          } catch (e) {
            // Mesure non trouvée
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[50]!, Colors.orange[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.straighten,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mesure != null
                              ? 'Mesure - ${mesure.nomMesure}'
                              : 'Mesure non définie',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mesure != null
                              ? '${mesure.genre.toUpperCase()} • ${mesure.tailleCm.toInt()}cm • ${mesure.poidsKg.toInt()}kg'
                              : 'Veuillez choisir une mesure',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _showMesureOptions(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      side:
                          const BorderSide(color: Color(0xFFFFA500), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      mesure != null ? 'Modifier' : 'Choisir',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFFA500),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isSubtotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '$value F',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSubtotal ? FontWeight.w500 : FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, ItemPanier item, PanierProvider panierProvider) {
    return Container(
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA500),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Retour au Panier',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showMesureOptions(BuildContext context) {
    final mesureProvider = Provider.of<MesureProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Modifier la mesure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Choisir une mesure existante
            if (mesureProvider.mesures.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFFFFA500),
                  ),
                ),
                title: const Text(
                  'Choisir une mesure existante',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${mesureProvider.mesures.length} mesure${mesureProvider.mesures.length > 1 ? 's' : ''} disponible${mesureProvider.mesures.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MesureExistanteScreen(
                        panierItemIndex: widget.panierItemIndex,
                        isModification: true,
                      ),
                    ),
                  );
                },
              ),

            if (mesureProvider.mesures.isNotEmpty) const SizedBox(height: 12),

            // Option 2: Créer une nouvelle mesure
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Créer une nouvelle mesure',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Prendre une nouvelle mesure',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MesureInformationsScreen(
                      panierItemIndex: widget.panierItemIndex,
                      isModification: true,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
