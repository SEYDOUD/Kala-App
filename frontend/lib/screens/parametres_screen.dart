import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'compte_screen.dart';
import 'conditions_screen.dart';
import 'aide_screen.dart';
import 'parametres_avances_screen.dart';
import 'login_screen.dart';

class ParametresScreen extends StatelessWidget {
  const ParametresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF3E2723),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF3E2723),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            // Compte
            _buildMenuItem(
              context,
              icon: Icons.account_circle_outlined,
              iconColor: const Color(0xFFFFA500),
              title: 'Compte',
              subtitle: 'Mot de passe, Modification des paramètres du compte',
              onTap: () {
                if (!authProvider.isAuthenticated) {
                  // Si non connecté, demander de se connecter
                  _showLoginDialog(context);
                } else {
                  // Si connecté, aller à la page compte
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompteScreen()),
                  );
                }
              },
            ),

            const Divider(height: 1, color: Color(0xFF5D4037)),

            // Conditions Générales
            _buildMenuItem(
              context,
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFFFFA500),
              title: 'Conditions Générales d\'utilisation',
              subtitle: 'Consultez nos conditions générales',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConditionsScreen()),
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFF5D4037)),

            // Aide
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              iconColor: const Color(0xFFFFA500),
              title: 'Aide',
              subtitle: 'Contact, centre d\'aide',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AideScreen()),
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFF5D4037)),

            // Paramètres Avancés
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              iconColor: const Color(0xFFFFA500),
              title: 'Paramètres Avancés',
              subtitle: 'Double Authentification, Suppression de Compte',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ParametresAvancesScreen()),
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFF5D4037)),

            const SizedBox(height: 40),

            // Déconnexion (seulement si connecté)
            if (authProvider.isAuthenticated)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: Colors.red[700],
                  child: InkWell(
                    onTap: () => _showLogoutDialog(context, authProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'DÉCONNEXION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icône carrée
              Container(
                width: 40,
                height: 40,
                color: iconColor.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              // Flèche
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text(
          'Connexion requise',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Vous devez être connecté pour accéder à votre compte. Voulez-vous vous connecter maintenant ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ANNULER',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              elevation: 0,
            ),
            child: const Text('SE CONNECTER'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ANNULER',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              elevation: 0,
            ),
            child: const Text('DÉCONNEXION'),
          ),
        ],
      ),
    );
  }
}
