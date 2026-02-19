import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/panier_provider.dart';
import 'panier_screen.dart';

class NoteCommandeScreen extends StatefulWidget {
  final int panierItemIndex;

  const NoteCommandeScreen({
    Key? key,
    required this.panierItemIndex,
  }) : super(key: key);

  @override
  State<NoteCommandeScreen> createState() => _NoteCommandeScreenState();
}

class _NoteCommandeScreenState extends State<NoteCommandeScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _continuer() {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);

    // Ajouter la note à l'item du panier
    if (_noteController.text.isNotEmpty) {
      panierProvider.updateItemNote(
          widget.panierItemIndex, _noteController.text);
    }

    // Aller au panier
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PanierScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panierProvider = Provider.of<PanierProvider>(context);
    final item = panierProvider.items[widget.panierItemIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: const Text('Note de Commande'),
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
          // En-tête avec info du modèle
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF3E2723),
            child: Row(
              children: [
                // Image du modèle
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.modele.imageUrl != null
                      ? Image.network(
                          item.modele.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[700],
                            child: const Icon(Icons.checkroom,
                                color: Colors.white),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[700],
                          child:
                              const Icon(Icons.checkroom, color: Colors.white),
                        ),
                ),
                const SizedBox(width: 12),
                // Info modèle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.modele.nom,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.modele.prixFormate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Corps blanc
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note de Commande',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez une spécification ou des détails supplémentaires pour votre commande (optionnel).',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Champ de texte pour la note
                    TextField(
                      controller: _noteController,
                      maxLines: 6,
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
                    const SizedBox(height: 32),

                    // Bouton Commenter
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continuer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
            ),
          ),
        ],
      ),
    );
  }
}
