import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/panier_provider.dart';

class NoteCommandeDialog extends StatefulWidget {
  final int panierItemIndex;

  const NoteCommandeDialog({
    Key? key,
    required this.panierItemIndex,
  }) : super(key: key);

  @override
  State<NoteCommandeDialog> createState() => _NoteCommandeDialogState();
}

class _NoteCommandeDialogState extends State<NoteCommandeDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _valider() {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);

    // Ajouter la note à l'item du panier
    if (_noteController.text.isNotEmpty) {
      panierProvider.updateItemNote(
          widget.panierItemIndex, _noteController.text);
    }

    Navigator.pop(context);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec bouton fermer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Note de Commande',
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
            const SizedBox(height: 16),

            // Champ de texte
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Une Specification ?',
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
                    color: Color(0xFFFFA500),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton Commenter
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _valider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Commenter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fonction helper pour afficher le dialog
Future<void> showNoteCommandeDialog(BuildContext context, int panierItemIndex) {
  return showDialog(
    context: context,
    builder: (context) => NoteCommandeDialog(panierItemIndex: panierItemIndex),
  );
}
