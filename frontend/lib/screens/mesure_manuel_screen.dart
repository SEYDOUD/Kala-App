import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesure_provider.dart';
import '../providers/panier_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../widgets/note_commande_dialog.dart';
import 'panier_screen.dart';

class MesureManuelScreen extends StatefulWidget {
  final int panierItemIndex;
  final String genre;
  final String nomMesure;
  final double tailleCm;
  final double poidsKg;
  final int age;
  final bool isModification;

  const MesureManuelScreen({
    Key? key,
    required this.panierItemIndex,
    required this.genre,
    required this.nomMesure,
    required this.tailleCm,
    required this.poidsKg,
    required this.age,
    this.isModification = false,
  }) : super(key: key);

  @override
  State<MesureManuelScreen> createState() => _MesureManuelScreenState();
}

class _MesureManuelScreenState extends State<MesureManuelScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers pour toutes les mesures
  final TextEditingController _tourDeTeteController = TextEditingController();
  final TextEditingController _epauleController = TextEditingController();
  final TextEditingController _dosController = TextEditingController();
  final TextEditingController _ventreController = TextEditingController();
  final TextEditingController _abdomenController = TextEditingController();
  final TextEditingController _cuisseController = TextEditingController();
  final TextEditingController _entreJambeController = TextEditingController();
  final TextEditingController _entrePiedController = TextEditingController();
  final TextEditingController _poitrineController = TextEditingController();

  bool _estParDefaut = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _tourDeTeteController.dispose();
    _epauleController.dispose();
    _dosController.dispose();
    _ventreController.dispose();
    _abdomenController.dispose();
    _cuisseController.dispose();
    _entreJambeController.dispose();
    _entrePiedController.dispose();
    _poitrineController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    // ─── Vérifier l'authentification ────────────────────────
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      // Afficher un dialog pour se connecter
      final bool? shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            'Vous devez être connecté pour enregistrer vos mesures. Voulez-vous vous connecter maintenant ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        // Aller à la page de connexion
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );

        // Si la connexion réussit, continuer l'enregistrement
        if (result == true && mounted) {
          _enregistrer(); // Rappeler la fonction après connexion
        }
      }
      return;
    }

    // ─── Utilisateur connecté, on continue ──────────────────
    setState(() {
      _isLoading = true;
    });

    final mesureProvider = Provider.of<MesureProvider>(context, listen: false);

    final data = {
      'nom_mesure': widget.nomMesure,
      'genre': widget.genre,
      'taille_cm': widget.tailleCm,
      'poids_kg': widget.poidsKg,
      'age': widget.age,
      'type_prise': 'manuel',
      'est_par_defaut': _estParDefaut,
      if (_tourDeTeteController.text.isNotEmpty)
        'tour_de_tete': double.parse(_tourDeTeteController.text),
      if (_epauleController.text.isNotEmpty)
        'epaule': double.parse(_epauleController.text),
      if (_dosController.text.isNotEmpty)
        'dos': double.parse(_dosController.text),
      if (_ventreController.text.isNotEmpty)
        'ventre': double.parse(_ventreController.text),
      if (_abdomenController.text.isNotEmpty)
        'abdomen': double.parse(_abdomenController.text),
      if (_cuisseController.text.isNotEmpty)
        'cuisse': double.parse(_cuisseController.text),
      if (_entreJambeController.text.isNotEmpty)
        'entre_jambe': double.parse(_entreJambeController.text),
      if (_entrePiedController.text.isNotEmpty)
        'entre_pied': double.parse(_entrePiedController.text),
      if (_poitrineController.text.isNotEmpty)
        'poitrine': double.parse(_poitrineController.text),
    };

    final success = await mesureProvider.createMesure(data);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Récupérer la mesure créée (la dernière)
      final mesureCreee = mesureProvider.mesures.first;

      // Sauvegarder l'ID dans le panier
      final panierProvider =
          Provider.of<PanierProvider>(context, listen: false);
      panierProvider.updateItemMesure(widget.panierItemIndex, mesureCreee.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesures enregistrées avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Si c'est une modification, retourner à la page de résumé
      if (widget.isModification) {
        Navigator.of(context).popUntil((route) =>
            route.settings.name == '/commande_resume' || route.isFirst);
        return;
      }

      // Sinon, aller à la page de note de commande (nouveau flow)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PanierScreen(),
        ),
        (route) => route.isFirst,
      );

      // Afficher la popup après un court délai
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showNoteCommandeDialog(context, widget.panierItemIndex);
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mesureProvider.errorMessage ??
              'Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mesures'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text(
                'Renseignez vos mesures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prenez vos mesures avec précision et renseignez-les ci-dessous.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Image aide visuelle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Ici vous pourrez ajouter une image de silhouette
                    Icon(
                      widget.genre == 'homme' ? Icons.man : Icons.woman,
                      size: 120,
                      color: const Color(0xFFFFA500),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.genre == 'homme'
                          ? 'Vue de Face - Homme'
                          : 'Vue de Face - Femme',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Champs de mesures
              _buildMesureField('Tour de tête', _tourDeTeteController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Épaule', _epauleController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Dos', _dosController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Ventre', _ventreController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Abdomen', _abdomenController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Cuisse', _cuisseController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Entre Jambe', _entreJambeController, 'cm'),
              const SizedBox(height: 16),
              _buildMesureField('Entre Pied', _entrePiedController, 'cm'),
              const SizedBox(height: 16),

              // Poitrine (pour femmes)
              if (widget.genre == 'femme')
                Column(
                  children: [
                    _buildMesureField('Poitrine', _poitrineController, 'cm'),
                    const SizedBox(height: 16),
                  ],
                ),

              // Option par défaut
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _estParDefaut,
                      onChanged: (value) {
                        setState(() {
                          _estParDefaut = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFFFA500),
                    ),
                    Expanded(
                      child: Text(
                        'Définir comme mesure par défaut',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMesureField(
      String label, TextEditingController controller, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Valeur invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
