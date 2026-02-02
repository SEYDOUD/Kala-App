import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/modele_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/modele_card.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'modele_detail_screen.dart';

class HomePublicScreen extends StatefulWidget {
  const HomePublicScreen({Key? key}) : super(key: key);

  @override
  State<HomePublicScreen> createState() => _HomePublicScreenState();
}

class _HomePublicScreenState extends State<HomePublicScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger les modèles au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModeleProvider>(context, listen: false)
          .loadModeles(refresh: true);
    });

    // Écouter le scroll pour le chargement infini
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ModeleProvider>(context, listen: false).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeleProvider = Provider.of<ModeleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.network(
          'https://via.placeholder.com/100x40/FFA500/FFFFFF?text=KALA',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'KALA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFA500),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // TODO: Panier
            },
          ),
          IconButton(
            icon: Icon(
              authProvider.isAuthenticated ? Icons.account_circle : Icons.login,
            ),
            onPressed: () {
              if (authProvider.isAuthenticated) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Recherchez des modèles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          modeleProvider.search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                modeleProvider.search(value);
              },
            ),
          ),

          // Filtres genre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildGenreFilter('Tous', 'tous', modeleProvider),
                const SizedBox(width: 12),
                _buildGenreFilter('Homme', 'homme', modeleProvider),
                const SizedBox(width: 12),
                _buildGenreFilter('Femme', 'femme', modeleProvider),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Costumes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${modeleProvider.total} modèles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des modèles
          Expanded(
            child: modeleProvider.isLoading && modeleProvider.modeles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : modeleProvider.modeles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun modèle disponible',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: modeleProvider.refresh,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: modeleProvider.modeles.length +
                              (modeleProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == modeleProvider.modeles.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final modele = modeleProvider.modeles[index];
                            return ModeleCard(
                              modele: modele,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ModeleDetailScreen(
                                      modeleId: modele.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFFA500),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          if (index == 3) {
            // Profil
            if (authProvider.isAuthenticated) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          }
          // TODO: Implémenter les autres onglets
        },
      ),
    );
  }

  Widget _buildGenreFilter(
      String label, String value, ModeleProvider provider) {
    final isSelected = provider.selectedGenre == value;

    return Expanded(
      child: InkWell(
        onTap: () => provider.setGenre(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFA500) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'homme'
                    ? Icons.man
                    : value == 'femme'
                        ? Icons.woman
                        : Icons.people,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
