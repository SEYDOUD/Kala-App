import 'package:flutter/material.dart';
import '../models/modele_model.dart';

class ModeleCard extends StatelessWidget {
  final ModeleModel modele;
  final VoidCallback onTap;

  const ModeleCard({
    Key? key,
    required this.modele,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Card avec SEULEMENT l'image ──────────────────────
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: modele.imageUrl != null
                      ? Image.network(
                          modele.imageUrl!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 170,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.checkroom,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Bouton favori (plus petit)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.favorite_border, size: 18),
                      color: Colors.grey[700],
                      onPressed: () {
                        // TODO: Ajouter aux favoris
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Tout le reste EN DEHORS du Card ──────────────────
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 8), // ← AJOUTÉ ICI
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < modele.noteMoyenne.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 12,
                        color: const Color(0xFFFFA500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${modele.nombreAvis})',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nom
                Text(
                  modele.nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Prix
                Text(
                  modele.prixFormate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
