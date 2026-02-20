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
    // Charger les mesures existantes
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
      // Passer à l'écran suivant avec les données
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MesureChoiceScreen(
            panierItemIndex: widget.panierItemIndex,
            genre: _genre,
            nomMesure: _nomController.text,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Prenez Vos Mesures'),
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
                'Informations',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez vos informations générales et renseignez votre taille, poids et âge pour cette mesure.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Genre
              const Text(
                'Genre*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGenreOption('Femme', 'femme', Icons.woman),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenreOption('Homme', 'homme', Icons.man),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nom de la mesure
              const Text(
                'Nom*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  hintText: 'Seydou',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Taille
              const Text(
                'Taille*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tailleController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '170',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'cm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Poids
              const Text(
                'Poids*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _poidsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '85',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Age
              const Text(
                'Age*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '22',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'âge est requis';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Valeur invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'an',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Bouton continuer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continuer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Prendre Votre Mesure',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // Bouton "Choisir une mesure existante" (si disponible)
              Consumer<MesureProvider>(
                builder: (context, mesureProvider, child) {
                  if (mesureProvider.mesures.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFFFFA500),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Choisir une mesure existante (${mesureProvider.mesures.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildGenreOption(String label, String value, IconData icon) {
    final isSelected = _genre == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _genre = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA500) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
