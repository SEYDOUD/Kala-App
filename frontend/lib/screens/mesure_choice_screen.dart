import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesure_provider.dart';
import '../widgets/prise_mesure_model_view.dart';
import 'mesure_existante_screen.dart';
import 'mesure_ia_guided_screen.dart';
import 'mesure_manuel_screen.dart';

class MesureChoiceScreen extends StatefulWidget {
  final int panierItemIndex;
  final String genre;
  final String nomMesure;
  final double tailleCm;
  final double poidsKg;
  final int age;
  final bool isModification;

  const MesureChoiceScreen({
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
  State<MesureChoiceScreen> createState() => _MesureChoiceScreenState();
}

class _MesureChoiceScreenState extends State<MesureChoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesureProvider>(context, listen: false).loadMesures();
    });
  }

  Future<void> _predictWithIa() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesureIaGuidedScreen(
          panierItemIndex: widget.panierItemIndex,
          genre: widget.genre,
          nomMesure: widget.nomMesure,
          tailleCm: widget.tailleCm,
          poidsKg: widget.poidsKg,
          age: widget.age,
          isModification: widget.isModification,
        ),
      ),
    );
  }

  void _goManual() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesureManuelScreen(
          panierItemIndex: widget.panierItemIndex,
          genre: widget.genre,
          nomMesure: widget.nomMesure,
          tailleCm: widget.tailleCm,
          poidsKg: widget.poidsKg,
          age: widget.age,
          isModification: widget.isModification,
        ),
      ),
    );
  }

  void _goExisting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesureExistanteScreen(
          panierItemIndex: widget.panierItemIndex,
          isModification: widget.isModification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Choisir la mesure'),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
      ),
      body: Consumer<MesureProvider>(
        builder: (context, mesureProvider, child) {
          return PriseMesureModelView(
            description: 'Comment souhaitez-vous\nprendre vos mesures ?',
            options: [
              PriseMesureOption(
                icon: Icons.smart_toy_outlined,
                title: 'Prendre avec l\'IA',
                subtitle: 'Guidage pose par pose',
                isEnabled: true,
                badge: 'Vision',
                onTap: _predictWithIa,
              ),
              PriseMesureOption(
                icon: Icons.edit_outlined,
                title: 'Saisir manuellement',
                subtitle: 'Entrez vos mesures',
                isEnabled: true,
                onTap: _goManual,
              ),
              if (mesureProvider.mesures.isNotEmpty)
                PriseMesureOption(
                  icon: Icons.history_outlined,
                  title: 'Choisir une mesure',
                  subtitle:
                      '${mesureProvider.mesures.length} mesure${mesureProvider.mesures.length > 1 ? 's' : ''} disponible${mesureProvider.mesures.length > 1 ? 's' : ''}',
                  isEnabled: true,
                  onTap: _goExisting,
                ),
            ],
          );
        },
      ),
    );
  }
}
