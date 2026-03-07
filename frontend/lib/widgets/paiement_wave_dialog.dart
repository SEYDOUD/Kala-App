import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/panier_provider.dart';
import '../services/commande_service.dart';
import '../services/pawapay_popup_listener.dart';
import 'commande_succes_dialog.dart';

class PaiementWaveDialog extends StatefulWidget {
  const PaiementWaveDialog({Key? key}) : super(key: key);

  @override
  State<PaiementWaveDialog> createState() => _PaiementWaveDialogState();
}

class _PaiementWaveDialogState extends State<PaiementWaveDialog> {
  final TextEditingController _telephoneController = TextEditingController();
  bool _isLoading = false;
  void Function()? _disposePopupListener;
  bool _popupReturned = false;
  bool _popupCancelled = false;

  @override
  void dispose() {
    _disposePopupListener?.call();
    _telephoneController.dispose();
    super.dispose();
  }

  String? _resolveReturnUrl() {
    if (!kIsWeb) return null;
    final base = Uri.base;
    final host = base.host.toLowerCase();
    final isLocalHost = host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
    if (base.scheme != 'https' || isLocalHost) {
      return null;
    }
    return '${base.scheme}://${base.authority}/payment-return';
  }

  Future<String> _waitForPaymentStatus(
    String commandeId, {
    Duration timeout = const Duration(minutes: 2),
    Duration pollingInterval = const Duration(seconds: 4),
  }) async {
    final startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final interval = _popupReturned ? const Duration(seconds: 1) : pollingInterval;
      await Future.delayed(interval);

      try {
        final commande = await CommandeService.getCommandeById(commandeId);
        final status = (commande['statut_paiement'] ?? 'en_attente').toString();
        if (status == 'paye' || status == 'echoue' || status == 'rembourse') {
          return status;
        }
      } catch (_) {
        // Keep polling; callback update can still arrive after transient errors.
      }
    }

    return 'timeout';
  }

  Future<void> _handlePayment() async {
    if (_telephoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numero de telephone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final panierProvider = Provider.of<PanierProvider>(context, listen: false);

      final commandeData = {
        'items': panierProvider.items.map((item) {
          return {
            'id_modele': item.modele.id,
            'quantite': item.quantite,
            'prix_unitaire': item.modele.prix,
            'tissus': item.tissusChoisis.map((tp) {
              return {
                'id_tissu': tp.tissu.id,
                'metrage': tp.metrage,
                'prix_unitaire': tp.tissu.prix,
                'sous_total': tp.sousTotal,
              };
            }).toList(),
            if (item.mesureId != null) 'id_mesure': item.mesureId,
            if (item.note != null) 'note': item.note,
            'sous_total': item.sousTotal,
          };
        }).toList(),
        'sous_total': panierProvider.total,
        'frais_livraison': 1500,
        'montant_total': panierProvider.total + 1500,
        'mode_paiement': 'wave',
      };

      final responseCommande = await CommandeService.createCommande(commandeData);
      final commandeId = responseCommande['commande']['_id'].toString();

      final responsePaiement = await CommandeService.processPayment(
        commandeId: commandeId,
        modePaiement: 'wave',
        telephone: _telephoneController.text.trim(),
        paymentFlow: 'payment_page',
        returnUrl: _resolveReturnUrl(),
      );

      final Map<String, dynamic> commande =
          (responsePaiement['commande'] as Map<String, dynamic>?) ?? {};
      final String numeroCommande = (commande['numero_commande'] ?? 'N/A').toString();
      final String reference =
          (responsePaiement['reference'] ?? commande['reference_paiement'] ?? 'N/A')
              .toString();
      final String? redirectUrl = responsePaiement['redirect_url']?.toString();

      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Lien de paiement pawaPay non recu');
      }

      _popupReturned = false;
      _popupCancelled = false;
      _disposePopupListener?.call();
      _disposePopupListener = registerPawapayMessageListener((payload) {
        final type = payload['type']?.toString().toLowerCase();
        if (type == 'return' || type == 'cancel') {
          _popupReturned = true;
          if (type == 'cancel') {
            _popupCancelled = true;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Retour marchand detecte, finalisation du paiement...'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      });

      final launched = await launchUrl(
        Uri.parse(redirectUrl),
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: 'pawapay_checkout',
      );

      if (!launched) {
        throw Exception('Impossible d ouvrir la popup pawaPay');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Popup pawaPay ouverte. Finalisez le paiement.'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      var finalStatus = await _waitForPaymentStatus(commandeId);
      if (finalStatus == 'timeout' && _popupCancelled) {
        finalStatus = 'echoue';
      }

      setState(() {
        _isLoading = false;
      });
      _disposePopupListener?.call();
      _disposePopupListener = null;

      if (!mounted) return;

      final parentContext = Navigator.of(context, rootNavigator: true).context;
      panierProvider.clear();
      Navigator.pop(context);

      final bool isPaid = finalStatus == 'paye';
      final bool isFailed = finalStatus == 'echoue';

      final String title = isPaid
          ? 'Paiement confirme'
          : isFailed
              ? 'Paiement echoue'
              : 'Paiement en attente';

      final String description = isPaid
          ? 'Votre paiement est confirme. La commande continue normalement.'
          : isFailed
              ? 'Le paiement a echoue. Vous pouvez relancer depuis Mes commandes.'
              : 'Le paiement est en cours de validation. Le statut sera mis a jour automatiquement.';

      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (context) => CommandeSuccesDialog(
          numeroCommande: numeroCommande,
          reference: reference,
          title: title,
          description: description,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _disposePopupListener?.call();
      _disposePopupListener = null;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android,
                color: Color(0xFF00BFFF),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paiement Mobile Money',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading
                  ? 'Confirmez le paiement dans la popup pawaPay puis attendez la confirmation.'
                  : 'Entrez votre numero Wave ou Orange Money',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Numero de telephone',
                hintText: '77 123 45 67',
                prefixIcon: const Icon(Icons.phone),
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
                    color: Color(0xFF00BFFF),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Payer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
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
}
