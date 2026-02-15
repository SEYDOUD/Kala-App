import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesure_provider.dart';
import '../models/mesure_model.dart';

class MesureExistanteScreen extends StatefulWidget {
  final int panierItemIndex;

  const MesureExistanteScreen({
    Key? key,
    required this.panierItemIndex,
  }) : super(key: key);

  @override
  State<MesureExistanteScreen> createState() => _MesureExistanteScreenState();
}

class _MesureExistanteScreenState extends State<MesureExistanteScreen> {
  String? _selectedMesureId;

  void _selectionner() {
    if (_selectedMesureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une mesure'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Associer la mesure à la commande
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesure sélectionnée avec succès !'),
        backgroundColor: Colors.green,
      ),
    );

    // Retourner à la page du modèle
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choisir une mesure'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<MesureProvider>(
        builder: (context, mesureProvider, child) {
          if (mesureProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (mesureProvider.mesures.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune mesure disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: mesureProvider.mesures.length,
                  itemBuilder: (context, index) {
                    final mesure = mesureProvider.mesures[index];
                    return _buildMesureCard(mesure);
                  },
                ),
              ),

              // Bouton sélectionner
              Container(
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
                    onPressed: _selectionner,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sélectionner',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMesureCard(MesureModel mesure) {
    final isSelected = _selectedMesureId == mesure.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMesureId = mesure.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFA500).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom et badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      mesure.genre == 'homme' ? Icons.man : Icons.woman,
                      color: const Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mesure.nomMesure,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (mesure.estParDefaut)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Par défaut',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Informations de base
            Row(
              children: [
                _buildInfoChip('${mesure.tailleCm.toInt()} cm'),
                const SizedBox(width: 8),
                _buildInfoChip('${mesure.poidsKg.toInt()} kg'),
                const SizedBox(width: 8),
                _buildInfoChip('${mesure.age} ans'),
              ],
            ),
            const SizedBox(height: 12),

            // Quelques mesures clés
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mesure.epaule != null)
                  _buildMesureChip('Épaule: ${mesure.epaule} cm'),
                if (mesure.dos != null)
                  _buildMesureChip('Dos: ${mesure.dos} cm'),
                if (mesure.ventre != null)
                  _buildMesureChip('Ventre: ${mesure.ventre} cm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMesureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFFFA500),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
