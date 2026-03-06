import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/mesure_provider.dart';
import '../providers/panier_provider.dart';
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
  final Map<String, double>? initialMesures;
  final bool isPrediction;

  const MesureManuelScreen({
    Key? key,
    required this.panierItemIndex,
    required this.genre,
    required this.nomMesure,
    required this.tailleCm,
    required this.poidsKg,
    required this.age,
    this.isModification = false,
    this.initialMesures,
    this.isPrediction = false,
  }) : super(key: key);

  @override
  State<MesureManuelScreen> createState() => _MesureManuelScreenState();
}

class _MesureManuelScreenState extends State<MesureManuelScreen> {
  final _formKey = GlobalKey<FormState>();

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
  void initState() {
    super.initState();
    _hydratePredictedMesures();
  }

  void _hydratePredictedMesures() {
    final initialMesures = widget.initialMesures;
    if (initialMesures == null) return;

    void fillIfPresent(String key, TextEditingController controller) {
      final value = initialMesures[key];
      if (value == null) return;
      controller.text = value.toStringAsFixed(1);
    }

    fillIfPresent('tour_de_tete', _tourDeTeteController);
    fillIfPresent('epaule', _epauleController);
    fillIfPresent('dos', _dosController);
    fillIfPresent('ventre', _ventreController);
    fillIfPresent('abdomen', _abdomenController);
    fillIfPresent('cuisse', _cuisseController);
    fillIfPresent('entre_jambe', _entreJambeController);
    fillIfPresent('entre_pied', _entrePiedController);
    fillIfPresent('poitrine', _poitrineController);
  }

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      final bool? shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            'Vous devez etre connecte pour enregistrer vos mesures. Voulez-vous vous connecter maintenant ?',
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );

        if (result == true && mounted) {
          _enregistrer();
        }
      }
      return;
    }

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
      'type_prise': widget.isPrediction ? 'ia' : 'manuel',
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
      final mesureCreee = mesureProvider.mesures.first;
      final panierProvider = Provider.of<PanierProvider>(context, listen: false);
      panierProvider.updateItemMesure(widget.panierItemIndex, mesureCreee.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesures enregistrees avec succes !'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.isModification) {
        Navigator.of(context).popUntil(
          (route) => route.settings.name == '/commande_resume' || route.isFirst,
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PanierScreen(),
        ),
        (route) => route.isFirst,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showNoteCommandeDialog(context, widget.panierItemIndex);
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mesureProvider.errorMessage ?? 'Erreur lors de l\'enregistrement',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Mesures'),
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Haut du corps',
                subtitle: 'Mesures de tete et buste',
                children: [
                  _buildMesureField(
                    label: 'Tour de tete',
                    controller: _tourDeTeteController,
                    icon: Icons.face_retouching_natural,
                  ),
                  _buildMesureField(
                    label: 'Epaule',
                    controller: _epauleController,
                    icon: Icons.accessibility_new,
                  ),
                  _buildMesureField(
                    label: 'Dos',
                    controller: _dosController,
                    icon: Icons.straighten,
                  ),
                  if (widget.genre == 'femme')
                    _buildMesureField(
                      label: 'Poitrine',
                      controller: _poitrineController,
                      icon: Icons.favorite_border,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Milieu du corps',
                subtitle: 'Mesures de ventre',
                children: [
                  _buildMesureField(
                    label: 'Ventre',
                    controller: _ventreController,
                    icon: Icons.radio_button_unchecked,
                  ),
                  _buildMesureField(
                    label: 'Abdomen',
                    controller: _abdomenController,
                    icon: Icons.circle_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Bas du corps',
                subtitle: 'Longueurs et jambes',
                children: [
                  _buildMesureField(
                    label: 'Cuisse',
                    controller: _cuisseController,
                    icon: Icons.directions_walk,
                  ),
                  _buildMesureField(
                    label: 'Entre jambe',
                    controller: _entreJambeController,
                    icon: Icons.height,
                  ),
                  _buildMesureField(
                    label: 'Entre pied',
                    controller: _entrePiedController,
                    icon: Icons.swap_vert,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDefaultCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                          'Enregistrer les mesures',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.genre == 'homme' ? Icons.man : Icons.woman,
                  color: const Color(0xFFF4A000),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Renseignez vos mesures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isPrediction
                          ? 'Valeurs pre-remplies par IA, vous pouvez ajuster.'
                          : 'Saisissez vos valeurs en centimetres.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6F6F6F),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPrediction)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7BF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'IA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF4A000),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('${widget.tailleCm.toStringAsFixed(0)} cm'),
              _buildInfoChip('${widget.poidsKg.toStringAsFixed(0)} kg'),
              _buildInfoChip('${widget.age} ans'),
              _buildInfoChip(widget.genre == 'homme' ? 'Homme' : 'Femme'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF454545),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDefaultCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE5B5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star_border,
            color: Color(0xFFF4A000),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Definir comme mesure par defaut',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _estParDefaut,
            onChanged: (value) {
              setState(() {
                _estParDefaut = value;
              });
            },
            activeColor: const Color(0xFFF4A000),
          ),
        ],
      ),
    );
  }

  Widget _buildMesureField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: const Color(0xFFF4A000),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ),
            SizedBox(
              width: 98,
              child: TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.0',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFF4A000),
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFD2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'cm',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF4A000),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}