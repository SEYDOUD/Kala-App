import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/commande_model.dart';
import '../providers/commande_provider.dart';
import '../services/commande_service.dart';
import '../services/upload_service.dart';

class CommandeDetailScreen extends StatefulWidget {
  final String commandeId;

  const CommandeDetailScreen({
    Key? key,
    required this.commandeId,
  }) : super(key: key);

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  static const Color _bgColor = Color(0xFFF6F3EF);
  static const Color _primary = Color(0xFFFFA500);

  static const List<_TimelineStep> _timelineSteps = [
    _TimelineStep(
      statusKey: 'en_attente',
      title: 'Validation',
      subtitle: 'Commande enregistree',
    ),
    _TimelineStep(
      statusKey: 'confirmee',
      title: 'Commande en tissus',
      subtitle: 'Tissus verifies et valides',
    ),
    _TimelineStep(
      statusKey: 'en_cours',
      title: 'Chez le tailleur',
      subtitle: 'Confection en cours',
    ),
    _TimelineStep(
      statusKey: 'prete',
      title: 'Repassage',
      subtitle: 'Finition et controle qualite',
    ),
    _TimelineStep(
      statusKey: 'terminee',
      title: 'Termine',
      subtitle: 'Commande remise et cloturee',
    ),
  ];

  final TextEditingController _retourController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  CommandeModel? _commande;
  bool _isLoading = true;
  bool _isUploadingRetourPhoto = false;
  bool _isSubmittingRetour = false;
  bool _isSubmittingSatisfaction = false;
  bool _isSubmittingCommentaire = false;
  final List<String> _retourPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadCommande();
  }

  @override
  void dispose() {
    _retourController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _loadCommande() async {
    final commandeProvider =
        Provider.of<CommandeProvider>(context, listen: false);
    final commande = await commandeProvider.getCommandeById(widget.commandeId);
    if (!mounted) {
      return;
    }

    setState(() {
      _commande = commande;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadRetourPhoto(ImageSource source) async {
    if (_isUploadingRetourPhoto) {
      return;
    }
    if (_retourPhotos.length >= 5) {
      _showInfo('Maximum 5 photos par retour.');
      return;
    }

    XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );
    } catch (error) {
      _showInfo('Impossible d ouvrir la camera ou la galerie: $error');
      return;
    }

    if (file == null) {
      return;
    }

    setState(() {
      _isUploadingRetourPhoto = true;
    });

    try {
      final uploadedUrl = await UploadService.uploadSingleXFile(file);
      if (!mounted) {
        return;
      }

      setState(() {
        _retourPhotos.add(uploadedUrl);
      });
      _showInfo('Photo ajoutee au retour.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInfo('Echec upload photo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingRetourPhoto = false;
        });
      }
    }
  }

  Future<void> _submitRetour() async {
    final commande = _commande;
    if (commande == null) {
      return;
    }

    final description = _retourController.text.trim();
    if (description.length < 5) {
      _showInfo('Decris les modifications a faire (minimum 5 caracteres).');
      return;
    }

    if (!commande.estLivree) {
      _showInfo('Retour disponible uniquement pour une commande terminee.');
      return;
    }

    if (commande.clientASatisfait) {
      _showInfo('Commande deja validee, retour non disponible.');
      return;
    }

    if (commande.retoursRestants <= 0) {
      _showInfo('Tu as atteint la limite de 3 retours.');
      return;
    }

    setState(() {
      _isSubmittingRetour = true;
    });

    try {
      final response = await CommandeService.createRetour(
        commandeId: commande.id,
        description: description,
        photos: _retourPhotos,
      );

      final updatedCommande = response['commande'];
      if (updatedCommande is Map<String, dynamic>) {
        setState(() {
          _commande = CommandeModel.fromJson(updatedCommande);
          _retourController.clear();
          _retourPhotos.clear();
        });
      } else {
        await _loadCommande();
      }

      if (!mounted) {
        return;
      }
      _showInfo('Retour enregistre avec succes.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInfo('Erreur lors de l envoi du retour: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRetour = false;
        });
      }
    }
  }

  Future<void> _validateSatisfaction() async {
    final commande = _commande;
    if (commande == null) {
      return;
    }

    setState(() {
      _isSubmittingSatisfaction = true;
    });

    try {
      final response = await CommandeService.validateSatisfaction(
        commandeId: commande.id,
        satisfait: true,
      );

      final updatedCommande = response['commande'];
      if (updatedCommande is Map<String, dynamic>) {
        setState(() {
          _commande = CommandeModel.fromJson(updatedCommande);
        });
      } else {
        await _loadCommande();
      }

      if (!mounted) {
        return;
      }
      _showInfo('Commande validee. Merci pour ton retour.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInfo('Erreur validation satisfaction: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSatisfaction = false;
        });
      }
    }
  }

  Future<void> _submitCommentaire() async {
    final commande = _commande;
    if (commande == null) {
      return;
    }

    final texte = _commentaireController.text.trim();
    if (texte.length < 3) {
      _showInfo('Commentaire trop court (minimum 3 caracteres).');
      return;
    }

    if (!commande.commentairesOuverts) {
      _showInfo(
        commande.estAnnulee
            ? 'Commentaire indisponible pour une commande annulee.'
            : 'Les commentaires sont fermes apres validation.',
      );
      return;
    }

    setState(() {
      _isSubmittingCommentaire = true;
    });

    try {
      final response = await CommandeService.createCommentaire(
        commandeId: commande.id,
        texte: texte,
      );

      final updatedCommande = response['commande'];
      if (updatedCommande is Map<String, dynamic>) {
        setState(() {
          _commande = CommandeModel.fromJson(updatedCommande);
          _commentaireController.clear();
        });
      } else {
        await _loadCommande();
      }

      if (!mounted) {
        return;
      }
      _showInfo('Commentaire envoye.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInfo('Erreur envoi commentaire: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingCommentaire = false;
        });
      }
    }
  }

  Future<void> _openVideoUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showInfo('Lien video invalide');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showInfo('Impossible d ouvrir la video');
    }
  }

  void _openPhotoPreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1F1F1F),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.white, size: 42),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_commande == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text(
            'Commande non trouvee',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    final commande = _commande!;
    final livraisonEstimee = commande.dateLivraisonEstimee ??
        commande.createdAt.add(const Duration(days: 7));

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Suivi de la Commande'),
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCommande,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(commande, livraisonEstimee),
              const SizedBox(height: 12),
              _buildTimelineCard(commande),
              const SizedBox(height: 12),
              _buildResultatCoutureSection(commande),
              const SizedBox(height: 12),
              _buildCommandeSection(commande),
              const SizedBox(height: 12),
              _buildFactureSection(commande),
              if (commande.estLivree) ...[
                const SizedBox(height: 12),
                _buildRetoursSection(commande),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CommandeModel commande, DateTime livraisonEstimee) {
    final status = _commandeStatusMeta(commande.statutGlobal);
    final paymentStatus = _paymentStatusMeta(commande.statutPaiement);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande ${commande.numeroCommande}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              _buildStatusPill(status.label, status.color),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(paymentStatus.label, paymentStatus.color),
              _buildStatusPill(
                _modePaiementLabel(commande.modePaiement),
                const Color(0xFF5D4037),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Date de commande', _formatDate(commande.createdAt)),
          const SizedBox(height: 8),
          _buildInfoRow('Livraison estimee', _formatDate(livraisonEstimee)),
          const SizedBox(height: 8),
          _buildInfoRow('Total', _formatMoney(commande.montantTotal),
              strongValue: true),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(CommandeModel commande) {
    final currentIndex = _statusIndex(commande.statut);
    final isCancelled = commande.statutGlobal == 'annulee';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suivi des etapes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ..._timelineSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final reached = !isCancelled && index <= currentIndex;
            final isCurrent = !isCancelled && index == currentIndex;
            final isLast = index == _timelineSteps.length - 1;
    final isFinalDone = isLast && commande.estLivree;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reached ? _primary : const Color(0xFFE0E0E0),
                        ),
                        child: Center(
                          child: isCurrent && !isFinalDone
                              ? const Icon(Icons.circle,
                                  size: 8, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: reached
                                        ? Colors.white
                                        : const Color(0xFF8B8B8B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: reached ? _primary : const Color(0xFFE0E0E0),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: reached
                            ? const Color(0xFFFFF8ED)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: reached
                              ? const Color(0xFFFFE2B3)
                              : const Color(0xFFECECEC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: reached
                                        ? const Color(0xFF3B2A1E)
                                        : const Color(0xFF7A7A7A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF737373),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reached
                                ? ((isCurrent && !isFinalDone)
                                    ? 'En cours'
                                    : 'Termine')
                                : 'A venir',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  reached ? _primary : const Color(0xFF9C9C9C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          if (isCancelled) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Cette commande a ete annulee.',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommandeSection(CommandeModel commande) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 18, color: Color(0xFF5A5A5A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Commande (${commande.items.length} article${commande.items.length > 1 ? 's' : ''})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Qte ${commande.totalQuantite}',
                style: const TextStyle(
                  color: Color(0xFF6D6D6D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...commande.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == commande.items.length - 1 ? 0 : 10),
              child: _buildArticleCard(item, index + 1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultatCoutureSection(CommandeModel commande) {
    final photos = commande.resultatCouturePhotos;
    final videos = commande.resultatCoutureVideos;
    final hasMedia = commande.hasResultatCouture;
    final commentairesOuverts = commande.commentairesOuverts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_creation_outlined,
                  size: 18, color: Color(0xFF5A5A5A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Resultat de couture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!hasMedia)
                const Text(
                  'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasMedia)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Aucun resultat disponible pour le moment.',
                style: TextStyle(color: Color(0xFF6A6A6A)),
              ),
            )
          else ...[
            if (photos.isNotEmpty) ...[
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photos.map((photo) {
                  return InkWell(
                    onTap: () => _openPhotoPreview(photo),
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (videos.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Videos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 6),
              Column(
                children: videos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return Container(
                    margin: EdgeInsets.only(bottom: index == videos.length - 1 ? 0 : 8),
                    child: InkWell(
                      onTap: () => _openVideoUrl(url),
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE2B3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.play_arrow, color: _primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Video ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.open_in_new, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 12),
          if (commande.commentairesClient.isNotEmpty) ...[
            const Text(
              'Commentaires client',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 6),
            ...commande.commentairesClient.asMap().entries.map((entry) {
              final index = entry.key;
              final commentaire = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == commande.commentairesClient.length - 1 ? 0 : 8),
                child: _buildCommentaireCard(commentaire),
              );
            }),
          ],
          if (commentairesOuverts && hasMedia) ...[
            if (commande.commentairesClient.isNotEmpty) const SizedBox(height: 12),
            _buildCommentaireForm(),
          ] else if (commentairesOuverts && !hasMedia)
            const Text(
              'Commentaires disponibles des que le resultat est publie.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            )
          else if (commande.estAnnulee)
            const Text(
              'Commentaire indisponible pour une commande annulee.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            )
          else
            const Text(
              'Commentaires fermes apres validation.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFactureSection(CommandeModel commande) {
    final lignesTotal = commande.totalArticlesCalcule;
    final sousTotal = commande.sousTotal > 0 ? commande.sousTotal : lignesTotal;
    final livraison = commande.fraisLivraison;
    final total = commande.montantTotal > 0
        ? commande.montantTotal
        : sousTotal + livraison;

    final ajustementArticles = sousTotal - lignesTotal;
    final ajustementTotal = total - (sousTotal + livraison);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: Color(0xFF5A5A5A)),
              const SizedBox(width: 8),
              const Text(
                'Facture',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLine('Articles commandes', _formatMoney(lignesTotal)),
          if (ajustementArticles.abs() >= 0.5)
            _buildLine('Ajustement articles', _formatMoney(ajustementArticles)),
          _buildLine('Sous-total', _formatMoney(sousTotal)),
          _buildLine('Livraison', _formatMoney(livraison)),
          if (ajustementTotal.abs() >= 0.5)
            _buildLine('Ajustement global', _formatMoney(ajustementTotal)),
          const Divider(height: 20),
          _buildLine('Total a payer', _formatMoney(total), bold: true),
          const SizedBox(height: 12),
          _buildLine(
              'Statut paiement', _paymentStatusMeta(commande.statutPaiement).label),
          if (commande.referencePaiement != null &&
              commande.referencePaiement!.trim().isNotEmpty)
            _buildLine(
              'Reference paiement',
              commande.referencePaiement!,
              ellipsis: true,
            ),
        ],
      ),
    );
  }

  Widget _buildRetoursSection(CommandeModel commande) {
    final retours = commande.retours;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_return_outlined,
                  size: 18, color: Color(0xFF5A5A5A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Retouches et validation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${commande.retoursRestants}/3 restantes',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF6C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu peux demander jusqu a 3 retouches apres livraison.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          if (retours.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Aucune retouche demandee pour cette commande.',
                style: TextStyle(color: Color(0xFF6A6A6A)),
              ),
            )
          else
            ...retours.asMap().entries.map((entry) {
              final index = entry.key;
              final retour = entry.value;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index == retours.length - 1 ? 0 : 8),
                child: _buildRetourCard(retour, index + 1),
              );
            }),
          const SizedBox(height: 12),
          if (!commande.clientASatisfait && commande.retoursRestants > 0)
            _buildRetourForm(),
          if (commande.clientASatisfait)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Commande validee par le client. Merci pour ta confiance.',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmittingSatisfaction ? null : _validateSatisfaction,
                icon: _isSubmittingSatisfaction
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified, size: 18),
                label: const Text('Valider si je suis satisfait'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(CommandeItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        border: Border.all(color: const Color(0xFFEDEDED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArticleVisual(item),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Article $index',
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.displayModeleNom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mesure: ${item.displayMesureNom}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLine('Quantite', 'x${item.quantite}'),
          _buildLine('Prix unitaire', _formatMoney(item.prixUnitaire)),
          _buildLine(
            'Tissus',
            item.tissus.isEmpty
                ? 'Aucun'
                : '${item.tissus.length} selection(s) - ${item.metrageTotal.toStringAsFixed(1)} m',
          ),
          if (item.tissus.isNotEmpty)
            _buildLine('Sous-total tissus', _formatMoney(item.totalTissus)),
          const Divider(height: 18),
          _buildLine('Total ligne', _formatMoney(item.sousTotal), bold: true),
          if (item.tissus.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSpecificationPanel(
              title: 'Specifications tissus',
              children: _buildTissuSpecRows(item),
            ),
          ],
          if (item.note != null && item.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSpecificationPanel(
              title: 'Note article',
              children: [
                Text(
                  item.note!.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E5E5E),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleVisual(CommandeItem item) {
    final imageUrls = item.imageUrls.where((url) => url.trim().isNotEmpty).toList();

    Widget fallback() {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.checkroom, color: Color(0xFF7D7D7D)),
      );
    }

    if (imageUrls.isEmpty) {
      return fallback();
    }

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrls.first,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrls.first,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+${imageUrls.length - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetourForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE1B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouvelle demande de retouche',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E3626),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _retourController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Explique les modifications a faire sur la commande...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isUploadingRetourPhoto
                    ? null
                    : () => _pickAndUploadRetourPhoto(ImageSource.camera),
                icon: _isUploadingRetourPhoto
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Capturer'),
              ),
              OutlinedButton.icon(
                onPressed: _isUploadingRetourPhoto
                    ? null
                    : () => _pickAndUploadRetourPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Galerie'),
              ),
            ],
          ),
          if (_retourPhotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _retourPhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: InkWell(
                        onTap: _isSubmittingRetour
                            ? null
                            : () {
                                setState(() {
                                  _retourPhotos.removeAt(index);
                                });
                              },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC62828),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingRetour ? null : _submitRetour,
              icon: _isSubmittingRetour
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: const Text('Envoyer la demande de retouche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetourCard(CommandeRetour retour, int index) {
    final statusMeta = _retourStatusMeta(retour.statut);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Retouche #$index',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildStatusPill(statusMeta.label, statusMeta.color),
            ],
          ),
          if (retour.createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Cree le ${_formatDate(retour.createdAt!)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF808080),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            retour.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3F3F3F),
            ),
          ),
          if (retour.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: retour.photos.map((photo) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photo,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFFE8E8E8),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if ((retour.commentaireAdmin ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E6E6)),
              ),
              child: Text(
                'Admin: ${retour.commentaireAdmin!.trim()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF626262),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentaireForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laisser un commentaire',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E3626),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentaireController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ton avis sur le resultat de couture...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingCommentaire ? null : _submitCommentaire,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSubmittingCommentaire
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer le commentaire'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaireCard(CommandeCommentaire commentaire) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (commentaire.createdAt != null)
            Text(
              _formatDate(commentaire.createdAt!),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A8A8A),
              ),
            ),
          if (commentaire.createdAt != null) const SizedBox(height: 4),
          Text(
            commentaire.texte,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3F3F3F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool strongValue = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: strongValue ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }

  Widget _buildLine(
    String label,
    String value, {
    bool bold = false,
    bool ellipsis = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF666666),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: ellipsis ? 1 : null,
              overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.visible,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF222222),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSpecificationPanel({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _buildTissuSpecRows(CommandeItem item) {
    final rows = <Widget>[];

    for (var i = 0; i < item.tissus.length; i++) {
      final tissu = item.tissus[i];
      rows.add(
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: i == item.tissus.length - 1 ? 0 : 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSpecLine('Tissu ${i + 1}', tissu.displayNom),
              if ((tissu.displayCouleur ?? '').trim().isNotEmpty)
                _buildSpecLine('Couleur', tissu.displayCouleur!),
              _buildSpecLine('Metrage', '${tissu.metrage.toStringAsFixed(1)} m'),
              _buildSpecLine('Prix unitaire', _formatMoney(tissu.prixUnitaire)),
              _buildSpecLine('Sous-total', _formatMoney(tissu.sousTotal)),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildSpecLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2A2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusMeta _commandeStatusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'terminee':
      case 'termine':
      case 'livree':
        return const _StatusMeta('Terminee', Color(0xFF2E7D32));
      case 'annulee':
      case 'annule':
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

  _StatusMeta _retourStatusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'resolu':
        return const _StatusMeta('Resolu', Color(0xFF2E7D32));
      case 'rejete':
        return const _StatusMeta('Rejete', Color(0xFFC62828));
      case 'en_traitement':
        return const _StatusMeta('En traitement', Color(0xFF1565C0));
      default:
        return const _StatusMeta('Demande', Color(0xFFEF6C00));
    }
  }

  int _statusIndex(String statut) {
    final normalized = statut.toLowerCase();
    switch (normalized) {
      case 'en_attente':
        return 0;
      case 'confirmee':
        return 1;
      case 'en_cours':
        return 2;
      case 'prete':
        return 3;
      case 'livree':
      case 'terminee':
      case 'termine':
        return 4;
      default:
        return 0;
    }
  }

  String _modePaiementLabel(String mode) {
    switch (mode) {
      case 'wave':
        return 'Wave';
      case 'orange_money':
        return 'Orange Money';
      case 'carte_visa':
        return 'Carte Visa';
      case 'especes':
        return 'Especes';
      default:
        return mode.isEmpty ? 'Paiement' : mode;
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
}

class _StatusMeta {
  final String label;
  final Color color;

  const _StatusMeta(this.label, this.color);
}

class _TimelineStep {
  final String statusKey;
  final String title;
  final String subtitle;

  const _TimelineStep({
    required this.statusKey,
    required this.title,
    required this.subtitle,
  });
}
