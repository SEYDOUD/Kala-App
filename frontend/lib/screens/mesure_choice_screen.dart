import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesure_provider.dart';
import 'mesure_manuel_screen.dart';
import 'mesure_existante_screen.dart';

class MesureChoiceScreen extends StatefulWidget {
  final int panierItemIndex;
  final String genre;
  final String nomMesure;
  final double tailleCm;
  final double poidsKg;
  final int age;

  const MesureChoiceScreen({
    Key? key,
    required this.panierItemIndex,
    required this.genre,
    required this.nomMesure,
    required this.tailleCm,
    required this.poidsKg,
    required this.age,
  }) : super(key: key);

  @override
  State<MesureChoiceScreen> createState() => _MesureChoiceScreenState();
}

class _MesureChoiceScreenState extends State<MesureChoiceScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les mesures existantes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesureProvider>(context, listen: false).loadMesures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choisir la mesure'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<MesureProvider>(
        builder: (context, mesureProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment souhaitez-vous prendre vos mesures ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Option 1 : IA (désactivée pour l'instant)
                _buildOptionCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'Prendre avec l\'IA',
                  subtitle: 'Utilisez l\'intelligence artificielle',
                  isEnabled: false,
                  badge: 'Bientôt disponible',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Fonctionnalité IA en cours de développement'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Option 2 : Manuel
                _buildOptionCard(
                  icon: Icons.edit_outlined,
                  title: 'Saisir manuellement',
                  subtitle: 'Entrez vos mesures vous-même',
                  isEnabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MesureManuelScreen(
                          panierItemIndex: widget.panierItemIndex,
                          genre: widget.genre,
                          nomMesure: widget.nomMesure,
                          tailleCm: widget.tailleCm,
                          poidsKg: widget.poidsKg,
                          age: widget.age,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Option 3 : Mesure existante (si disponible)
                if (mesureProvider.mesures.isNotEmpty)
                  _buildOptionCard(
                    icon: Icons.history_outlined,
                    title: 'Choisir une mesure existante',
                    subtitle:
                        '${mesureProvider.mesures.length} mesure${mesureProvider.mesures.length > 1 ? 's' : ''} disponible${mesureProvider.mesures.length > 1 ? 's' : ''}',
                    isEnabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MesureExistanteScreen(
                            panierItemIndex: widget.panierItemIndex,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? const Color(0xFFFFA500) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFFFFA500).withOpacity(0.1)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled ? const Color(0xFFFFA500) : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? const Color(0xFFFFA500) : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
