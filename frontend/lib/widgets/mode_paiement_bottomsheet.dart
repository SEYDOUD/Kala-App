import 'package:flutter/material.dart';
import 'paiement_wave_dialog.dart';

class ModePaiementBottomSheet extends StatefulWidget {
  const ModePaiementBottomSheet({Key? key}) : super(key: key);

  @override
  State<ModePaiementBottomSheet> createState() =>
      _ModePaiementBottomSheetState();
}

class _ModePaiementBottomSheetState extends State<ModePaiementBottomSheet> {
  String? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre avec bouton fermer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mode de Paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Option Mobile Money
                _buildPaymentOption(
                  mode: 'wave',
                  icon: Icons.phone_android,
                  iconColor: const Color(0xFF00BFFF),
                  title: 'Mobile Money',
                  subtitle:
                      'Vous pouvez payer par Mobile Money , Wave ou Orange Money et vous serez livré à la date convenue.',
                ),
                const SizedBox(height: 16),

                // Option Carte Visa
                _buildPaymentOption(
                  mode: 'carte_visa',
                  icon: Icons.credit_card,
                  iconColor: Colors.blue[900]!,
                  title: 'Carte Visa',
                  subtitle:
                      'Vous pouvez payer par Carte crédit Visa et recevoir votre commande sous voyez dans le monde',
                  isDisabled: true,
                ),
                const SizedBox(height: 24),

                // Bouton Sélectionner
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedMode != null ? _handleSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text(
                      'Sélectionner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String mode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedMode = mode;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFA500)
                : (isDisabled ? Colors.grey[300]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDisabled ? Colors.grey[200] : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDisabled ? Colors.grey : iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDisabled ? Colors.grey : Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Radio
            Radio<String>(
              value: mode,
              groupValue: _selectedMode,
              onChanged: isDisabled
                  ? null
                  : (value) {
                      setState(() {
                        _selectedMode = value;
                      });
                    },
              activeColor: const Color(0xFFFFA500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelection() async {
    if (_selectedMode == null) return;

    Navigator.pop(context);

    if (_selectedMode == 'wave') {
      // Ouvrir le dialog de paiement Wave
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PaiementWaveDialog(),
      );
    } else if (_selectedMode == 'carte_visa') {
      // TODO: Implémenter le paiement par carte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement par carte en cours de développement'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// Fonction helper pour afficher le BottomSheet
Future<void> showModePaiementBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ModePaiementBottomSheet(),
  );
}
