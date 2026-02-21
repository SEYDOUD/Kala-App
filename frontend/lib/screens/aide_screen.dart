import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AideScreen extends StatelessWidget {
  const AideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aide'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact
          _buildSection(
            title: 'Nous contacter',
            children: [
              _buildContactTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'support@kala.sn',
                onTap: () => _launchEmail('support@kala.sn'),
              ),
              _buildContactTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                subtitle: '+221 77 123 45 67',
                onTap: () => _launchPhone('+221771234567'),
              ),
              _buildContactTile(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                subtitle: 'Chattez avec nous',
                onTap: () => _launchWhatsApp('+221771234567'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FAQ
          _buildSection(
            title: 'Questions fréquentes',
            children: [
              _buildFaqTile(
                question: 'Comment passer une commande ?',
                answer:
                    'Sélectionnez un modèle, choisissez vos tissus, prenez vos mesures et procédez au paiement.',
              ),
              _buildFaqTile(
                question: 'Quels modes de paiement acceptez-vous ?',
                answer:
                    'Nous acceptons Wave, Orange Money et les cartes bancaires.',
              ),
              _buildFaqTile(
                question: 'Quel est le délai de livraison ?',
                answer:
                    'Le délai varie selon la complexité de la commande, généralement entre 5 et 15 jours.',
              ),
              _buildFaqTile(
                question: 'Puis-je modifier ma commande ?',
                answer:
                    'Les modifications sont possibles dans les 24h suivant la commande.',
              ),
              _buildFaqTile(
                question: 'Comment prendre mes mesures correctement ?',
                answer:
                    'Suivez le guide de prise de mesures dans l\'application ou contactez-nous pour assistance.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA500).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFFFA500)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildFaqTile({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
