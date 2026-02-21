import 'package:flutter/material.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Conditions Générales'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conditions Générales d\'Utilisation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                '1. Acceptation des conditions',
                'En utilisant l\'application Kala, vous acceptez d\'être lié par ces conditions générales d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
              ),
              _buildSection(
                '2. Services proposés',
                'Kala est une plateforme de commande de vêtements sur mesure. Nous mettons en relation les clients avec des tailleurs qualifiés pour la confection de vêtements personnalisés.',
              ),
              _buildSection(
                '3. Compte utilisateur',
                'Vous devez créer un compte pour utiliser nos services. Vous êtes responsable de la confidentialité de vos identifiants et de toutes les activités effectuées sous votre compte.',
              ),
              _buildSection(
                '4. Commandes et paiements',
                'Les commandes sont confirmées après le paiement. Les prix affichés incluent la confection et les frais de livraison. Les paiements peuvent être effectués par Mobile Money ou carte bancaire.',
              ),
              _buildSection(
                '5. Livraison',
                'Les délais de livraison sont communiqués lors de la commande. Nous nous efforçons de respecter ces délais, mais des retards peuvent survenir.',
              ),
              _buildSection(
                '6. Politique de retour',
                'Les articles sur mesure ne peuvent être retournés que s\'ils ne correspondent pas aux spécifications commandées. Les retours doivent être signalés dans les 48h suivant la réception.',
              ),
              _buildSection(
                '7. Protection des données',
                'Nous nous engageons à protéger vos données personnelles conformément à notre politique de confidentialité.',
              ),
              _buildSection(
                '8. Modification des conditions',
                'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications seront effectives dès leur publication dans l\'application.',
              ),
              const SizedBox(height: 20),
              Text(
                'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFA500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
