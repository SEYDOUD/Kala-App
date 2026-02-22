import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/panier_provider.dart';
import '../services/commande_service.dart';
import 'commande_succes_dialog.dart';

class PaiementWaveDialog extends StatefulWidget {
  const PaiementWaveDialog({Key? key}) : super(key: key);

  @override
  State<PaiementWaveDialog> createState() => _PaiementWaveDialogState();
}

class _PaiementWaveDialogState extends State<PaiementWaveDialog> {
  final TextEditingController _telephoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final panierProvider =
          Provider.of<PanierProvider>(context, listen: false);

      // 1. Créer la commande
      final commandeData = {
        'items': panierProvider.items.map((item) {
          return {
            'id_modele': item.modele.id,
            'quantite': item.quantite,
            'prix_unitaire': item.modele.prix,
            'tissus': item.tissusChoisis.map((tp) {
              return {
                'id_tissu': tp.tissu.id,
                'metrage': tp.metrage,
                'prix_unitaire': tp.tissu.prix,
                'sous_total': tp.sousTotal,
              };
            }).toList(),
            if (item.mesureId != null) 'id_mesure': item.mesureId,
            if (item.note != null) 'note': item.note,
            'sous_total': item.sousTotal,
          };
        }).toList(),
        'sous_total': panierProvider.total,
        'frais_livraison': 1500,
        'montant_total': panierProvider.total + 1500,
        'mode_paiement': 'wave',
      };

      final responseCommande =
          await CommandeService.createCommande(commandeData);
      final commandeId = responseCommande['commande']['_id'];

      print('✅ Commande créée avec ID: $commandeId'); // ← AJOUTEZ
      print('📦 Response complète: $responseCommande');

      // 2. Simuler le paiement Wave (en attendant l'intégration réelle)
      await Future.delayed(const Duration(seconds: 2));

      final responsePaiement = await CommandeService.processPayment(
        commandeId: commandeId,
        modePaiement: 'wave',
        telephone: _telephoneController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Vider le panier
        panierProvider.clear();

        // Fermer le dialog de paiement
        Navigator.pop(context);

        // Afficher le dialog de succès
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CommandeSuccesDialog(
            numeroCommande: responsePaiement['commande']['numero_commande'],
            reference: responsePaiement['reference'],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône Wave
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android,
                color: Color(0xFF00BFFF),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Paiement Mobile Money',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Entrez votre numéro Wave ou Orange Money',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Champ numéro de téléphone
            TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '77 123 45 67',
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00BFFF),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Payer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
