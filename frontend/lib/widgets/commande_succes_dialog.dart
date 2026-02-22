import 'package:flutter/material.dart';
import '../screens/mes_commandes_screen.dart';
import 'package:provider/provider.dart';
import '../providers/commande_provider.dart';

class CommandeSuccesDialog extends StatelessWidget {
  final String numeroCommande;
  final String reference;

  const CommandeSuccesDialog({
    Key? key,
    required this.numeroCommande,
    required this.reference,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône succès avec animation
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green[600],
                size: 60,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            const Text(
              'Commande Confirmée avec Succès',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Détails
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('N° Commande', numeroCommande),
                  const SizedBox(height: 8),
                  _buildDetailRow('Référence', reference),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton OK
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Fermer le dialog
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  // Naviguer vers la page des commandes
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (_) => const MesCommandesScreen(),
                    ),
                  )
                      .then((_) {
                    // Recharger les commandes après navigation
                    Provider.of<CommandeProvider>(context, listen: false)
                        .loadCommandes();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir mes commandes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
