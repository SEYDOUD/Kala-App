import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commande_model.dart';
import '../providers/auth_provider.dart';
import '../providers/commande_provider.dart';
import '../providers/panier_provider.dart';
import 'commande_detail_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'panier_screen.dart';

class MesCommandesScreen extends StatefulWidget {
  const MesCommandesScreen({Key? key}) : super(key: key);

  @override
  State<MesCommandesScreen> createState() => _MesCommandesScreenState();
}

class _MesCommandesScreenState extends State<MesCommandesScreen> {
  static const Color _bgColor = Color(0xFFF6F3EF);
  static const Color _primary = Color(0xFFFFA500);

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

  Future<void> _refresh() async {
    await Provider.of<CommandeProvider>(context, listen: false).loadCommandes();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticated(context);
    }

    final commandeProvider = Provider.of<CommandeProvider>(context);
    final commandes = commandeProvider.commandes;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes Commandes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
          Consumer<PanierProvider>(
            builder: (context, panierProvider, child) {
              final itemCount = panierProvider.items.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PanierScreen()),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Text(
                          itemCount > 9 ? '9+' : '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (commandeProvider.isLoading && commandes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                ],
              );
            }

            if (commandes.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildOverview(<CommandeModel>[]),
                  const SizedBox(height: 16),
                  _buildEmptyState(),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: commandes.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildOverview(commandes);
                }
                final commande = commandes[index - 1];
                return _buildCommandeCard(context, commande);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildOverview(List<CommandeModel> commandes) {
    final enCours = commandes
        .where((c) => !const ['terminee', 'annulee'].contains(c.statutGlobal))
        .length;
    final terminees = commandes.where((c) => c.statutGlobal == 'terminee').length;
    final total = commandes.length;

    Widget statTile(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF696969),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        statTile('Total', '$total', const Color(0xFF3E2723)),
        const SizedBox(width: 10),
        statTile('En cours', '$enCours', const Color(0xFFFFA500)),
        const SizedBox(width: 10),
        statTile('Terminees', '$terminees', const Color(0xFF2E7D32)),
      ],
    );
  }

  Widget _buildCommandeCard(BuildContext context, CommandeModel commande) {
    final status = _commandeStatusMeta(commande.statutGlobal);
    final paymentStatus = _paymentStatusMeta(commande.statutPaiement);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommandeDetailScreen(commandeId: commande.id),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommandeVisual(commande),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commande ${commande.numeroCommande}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDate(commande.createdAt)} - ${commande.items.length} modele(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildModeleSummary(commande),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildMesureSummary(commande),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildStatusBadge(status),
                      _buildStatusBadge(paymentStatus, outlined: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(commande.montantTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9E9E9)),
                  ),
                  child: Text(
                    'Qte ${commande.totalQuantite}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandeVisual(CommandeModel commande) {
    final imageUrls = commande.items
        .expand((item) => item.imageUrls)
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList();

    Widget fallback() {
      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.checkroom, color: Color(0xFF8C8C8C), size: 28),
      );
    }

    if (imageUrls.isEmpty) {
      return fallback();
    }

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrls.first,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
          ),
          if (imageUrls.length > 1)
            Positioned(
              right: -4,
              top: -4,
              child: _buildMiniImageChip(imageUrls[1]),
            ),
          if (imageUrls.length > 2)
            Positioned(
              right: -4,
              bottom: -4,
              child: _buildMiniImageChip(imageUrls[2]),
            ),
          if (imageUrls.length > 1)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${imageUrls.length - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniImageChip(String imageUrl) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7E7E7)),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(_StatusMeta status, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : status.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.background),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: outlined ? status.background : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildMesureSummary(CommandeModel commande) {
    final names = <String>{};
    for (final item in commande.items) {
      final nom = item.mesureInfo?.nomMesure;
      if (nom != null && nom.trim().isNotEmpty) {
        names.add(nom.trim());
      }
    }

    if (names.isEmpty) {
      return 'Mesure: non renseignee';
    }
    if (names.length == 1) {
      return 'Mesure: ${names.first}';
    }
    return 'Mesures: ${names.length} profils';
  }

  String _buildModeleSummary(CommandeModel commande) {
    final names = <String>[];
    for (final item in commande.items) {
      final nom = item.displayModeleNom.trim();
      if (nom.isEmpty) {
        continue;
      }
      if (!names.contains(nom)) {
        names.add(nom);
      }
    }

    if (names.isEmpty) {
      return 'Modeles: non renseignes';
    }
    if (names.length == 1) {
      return 'Modele: ${names.first}';
    }
    if (names.length == 2) {
      return 'Modeles: ${names.first}, ${names.last}';
    }
    return 'Modeles: ${names[0]}, ${names[1]} +${names.length - 2}';
  }

  _StatusMeta _commandeStatusMeta(String status) {
    switch (status) {
      case 'terminee':
      case 'termine':
      case 'livree':
        return const _StatusMeta('Terminee', Color(0xFF2E7D32));
      case 'annule':
      case 'annulee':
        return const _StatusMeta('Annulee', Color(0xFFC62828));
      case 'en_cours':
      case 'confirmee':
      case 'prete':
        return const _StatusMeta('En cours', _primary);
      default:
        return const _StatusMeta('En attente', Color(0xFF8D6E63));
    }
  }

  _StatusMeta _paymentStatusMeta(String status) {
    switch (status) {
      case 'paye':
        return const _StatusMeta('Paye', Color(0xFF2E7D32));
      case 'echoue':
        return const _StatusMeta('Paiement echoue', Color(0xFFC62828));
      case 'rembourse':
        return const _StatusMeta('Rembourse', Color(0xFF6A1B9A));
      default:
        return const _StatusMeta('Paiement en attente', Color(0xFFEF6C00));
    }
  }

  String _formatMoney(double value) {
    final rounded = value.round().toString();
    final grouped = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$grouped F';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande pour le moment',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaitront ici avec leur statut et leur facture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 66, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                'Connexion requise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _primary,
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
          Navigator.pop(context);
        } else if (index == 3) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      },
    );
  }
}

class _StatusMeta {
  final String label;
  final Color background;

  const _StatusMeta(this.label, this.background);
}
