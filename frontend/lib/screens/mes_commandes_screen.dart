import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/commande_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/panier_provider.dart';
import 'commande_detail_screen.dart';
import 'panier_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../models/commande_model.dart';

class MesCommandesScreen extends StatefulWidget {
  const MesCommandesScreen({Key? key}) : super(key: key);

  @override
  State<MesCommandesScreen> createState() => _MesCommandesScreenState();
}

class _MesCommandesScreenState extends State<MesCommandesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<CommandeProvider>(context, listen: false).loadCommandes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticated(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Mes Commandes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Badge panier
          Consumer<PanierProvider>(
            builder: (context, panierProvider, child) {
              final itemCount = panierProvider.items.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PanierScreen()),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            itemCount > 9 ? '9+' : '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<CommandeProvider>(
        builder: (context, commandeProvider, child) {
          if (commandeProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA500)),
            );
          }

          if (commandeProvider.commandes.isEmpty) {
            return _buildEmptyState(context);
          }

          return Container(
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: commandeProvider.commandes.length,
              itemBuilder: (context, index) {
                final commande = commandeProvider.commandes[index];
                return _buildCommandeCard(context, commande);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('🔄 Test manuel chargement commandes...');
          await Provider.of<CommandeProvider>(context, listen: false)
              .loadCommandes();
          print('✅ Test terminé');
        },
        backgroundColor: const Color(0xFFFFA500),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildCommandeCard(BuildContext context, CommandeModel commande) {
    final isEnCours =
        commande.statut != 'livree' && commande.statut != 'annulee';
    final statusColor = isEnCours ? const Color(0xFFFFA500) : Colors.green;
    final statusText = isEnCours ? 'En Cours' : 'Terminé';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommandeDetailScreen(commandeId: commande.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
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
            // Image du premier item
            ClipRRect(
              child: commande.items.isNotEmpty &&
                      commande.items[0].idModele != null
                  ? Image.network(
                      'URL_IMAGE', // TODO: Récupérer depuis le modèle
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.checkroom),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.checkroom),
                    ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nom
                  Text(
                    'Commande ${commande.numeroCommande}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Sous-titre
                  Text(
                    'Mesures : seydou',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Prix
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${commande.montantTotal.toStringAsFixed(0)} F',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Qté',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '${commande.items.fold<int>(0, (int sum, CommandeItem item) => sum + item.quantite)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Connexion requise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFFA500),
      unselectedItemColor: Colors.grey,
      currentIndex: 2,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
      ],
      onTap: (index) {
        if (index == 0) {
          // Accueil
          Navigator.pop(context);
        } else if (index == 2) {
          // Commandes (déjà sur cette page, ne rien faire)
        } else if (index == 3) {
          // Profil
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
        // TODO: Favoris (index == 1)
      },
    );
  }
}
