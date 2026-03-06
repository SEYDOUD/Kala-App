import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mesure_provider.dart';
import 'mesure_choice_screen.dart';
import 'mesure_existante_screen.dart';

class MesureInformationsScreen extends StatefulWidget {
  final int panierItemIndex;
  final bool isModification;

  const MesureInformationsScreen({
    Key? key,
    required this.panierItemIndex,
    this.isModification = false,
  }) : super(key: key);

  @override
  State<MesureInformationsScreen> createState() =>
      _MesureInformationsScreenState();
}

class _MesureInformationsScreenState extends State<MesureInformationsScreen> {
  final _formKey = GlobalKey<FormState>();

  String _genre = 'homme';
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _tailleController = TextEditingController();
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesureProvider>(context, listen: false).loadMesures();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _continuer() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MesureChoiceScreen(
            panierItemIndex: widget.panierItemIndex,
            genre: _genre,
            nomMesure: _nomController.text.trim(),
            tailleCm: double.parse(_tailleController.text),
            poidsKg: double.parse(_poidsController.text),
            age: int.parse(_ageController.text),
            isModification: widget.isModification,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Prenez vos mesures'),
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
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Identite',
                subtitle: 'Nom et genre pour cette mesure',
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Nom',
                      hint: 'Seydou',
                      controller: _nomController,
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGenreRow(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Profil physique',
                subtitle: 'Ces informations servent a la prediction IA',
                child: Column(
                  children: [
                    _buildNumberField(
                      label: 'Taille',
                      hint: '170',
                      unit: 'cm',
                      icon: Icons.height,
                      controller: _tailleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La taille est requise';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Valeur invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildNumberField(
                      label: 'Poids',
                      hint: '85',
                      unit: 'kg',
                      icon: Icons.monitor_weight_outlined,
                      controller: _poidsController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le poids est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Valeur invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildNumberField(
                      label: 'Age',
                      hint: '22',
                      unit: 'ans',
                      icon: Icons.cake_outlined,
                      controller: _ageController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'age est requis';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Valeur invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continuer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continuer vers la prise de mesure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Consumer<MesureProvider>(
                builder: (context, mesureProvider, child) {
                  if (mesureProvider.mesures.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MesureExistanteScreen(
                                panierItemIndex: widget.panierItemIndex,
                                isModification: widget.isModification,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, size: 18),
                        label: Text(
                          'Choisir une mesure existante (${mesureProvider.mesures.length})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF4A000),
                          side: const BorderSide(
                            color: Color(0xFFF4A000),
                            width: 1.8,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune,
              color: Color(0xFFF4A000),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations de base',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Remplissez ces champs avant la prise de mesure IA.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6F6F6F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildGenreRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGenreOption('Femme', 'femme', Icons.woman),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGenreOption('Homme', 'homme', Icons.man),
        ),
      ],
    );
  }

  Widget _buildGenreOption(String label, String value, IconData icon) {
    final isSelected = _genre == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _genre = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4A000) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4A000) : const Color(0xFFE4E4E4),
            width: 1.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF666666),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return _buildFieldShell(
      label: label,
      icon: icon,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFF4A000), width: 1.4),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required String unit,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return _buildFieldShell(
      label: label,
      icon: icon,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                  borderSide:
                      const BorderSide(color: Color(0xFFF4A000), width: 1.4),
                ),
              ),
              validator: validator,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFD2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF4A000),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldShell({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFFF4A000),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$label*',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
