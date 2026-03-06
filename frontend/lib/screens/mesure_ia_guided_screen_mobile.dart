import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;

import '../services/mesure_service.dart';
import 'mesure_manuel_screen.dart';

class MesureIaGuidedScreen extends StatefulWidget {
  final int panierItemIndex;
  final String genre;
  final String nomMesure;
  final double tailleCm;
  final double poidsKg;
  final int age;
  final bool isModification;

  const MesureIaGuidedScreen({
    super.key,
    required this.panierItemIndex,
    required this.genre,
    required this.nomMesure,
    required this.tailleCm,
    required this.poidsKg,
    required this.age,
    this.isModification = false,
  });

  @override
  State<MesureIaGuidedScreen> createState() => _MesureIaGuidedScreenState();
}

class _MesureIaGuidedScreenState extends State<MesureIaGuidedScreen> {
  CameraController? _cameraController;
  Timer? _analyzeTimer;
  Timer? _countdownTimer;
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = true;
  bool _isAnalyzing = false;
  bool _isCameraReady = false;
  bool _hasVisionFeedback = false;
  bool _poseOk = false;
  double _stabilityScore = 0.0;

  String? _sessionId;
  String _currentPose = 'front_relaxed';
  String _instruction = 'Initialisation de la session IA...';
  String? _error;

  int? _countdown;
  int _countdownWeakFrames = 0;
  String _lastSpoken = '';
  DateTime _lastSpeechAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _setupTts();
    _initFlow();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text, {bool force = false}) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final tooSoon = now.difference(_lastSpeechAt).inMilliseconds < 3500;
    if (!force && text == _lastSpoken && tooSoon) return;

    _lastSpoken = text;
    _lastSpeechAt = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _initFlow() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.wait([
      _startSession(),
      _initializeCamera(),
    ]);

    if (!mounted) return;

    _startLiveAnalysis();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startSession() async {
    try {
      final response = await MesureService.startVisionSession({
        'genre': widget.genre,
        'taille_cm': widget.tailleCm,
        'poids_kg': widget.poidsKg,
        'age': widget.age,
      });

      if (!mounted) return;
      setState(() {
        _sessionId = response['session_id']?.toString();
        _currentPose = response['current_pose']?.toString() ?? _currentPose;
        _instruction = response['instruction']?.toString() ?? _instruction;
      });

      await _speak(_instruction, force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Aucune camera disponible');
      }

      final selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Camera indisponible: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  void _startLiveAnalysis() {
    if (_sessionId == null || !_isCameraReady || _cameraController == null) {
      return;
    }

    _analyzeTimer?.cancel();
    _analyzeTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _captureAndAnalyzeLiveFrame(confirmCapture: false);
    });
  }

  Future<void> _captureAndAnalyzeLiveFrame({required bool confirmCapture}) async {
    if (!mounted || _isAnalyzing || _sessionId == null || _cameraController == null) {
      return;
    }

    _isAnalyzing = true;

    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final optimizedBytes = _optimizeFrameBytes(bytes);
      final base64Image = base64Encode(optimizedBytes);

      final response = await MesureService.analyzeVisionFrame(
        _sessionId!,
        base64Image,
        confirmCapture: confirmCapture,
      );

      if (!mounted) return;

      if (response['completed'] == true) {
        _analyzeTimer?.cancel();
        _countdownTimer?.cancel();
        final raw = response['mesures_predites'];
        final predicted = <String, double>{};
        if (raw is Map<String, dynamic>) {
          raw.forEach((k, v) {
            if (v is num) predicted[k] = v.toDouble();
          });
        }

        await _speak('Capture terminee. Mesures predites avec succes.', force: true);

        if (!mounted) return;
        Navigator.pushReplacement(
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
              initialMesures: predicted,
              isPrediction: true,
            ),
          ),
        );
        return;
      }

      final poseOk = response['pose_ok'] == true;
      final nextPose = response['current_pose']?.toString() ?? _currentPose;
      final instruction = response['instruction']?.toString() ?? _instruction;
      final advanced = response['advanced'] == true;
      final stability = (response['stability_score'] is num)
          ? (response['stability_score'] as num).toDouble()
          : (poseOk ? 1.0 : 0.0);

      setState(() {
        _hasVisionFeedback = true;
        _poseOk = poseOk;
        _stabilityScore = stability;
        _currentPose = nextPose;
        _instruction = instruction;
      });

      if (advanced) {
        _cancelCountdown();
        await _speak('Pose validee. ${_poseLabel(nextPose)}. $instruction', force: true);
        return;
      }

      if (!confirmCapture) {
        final stableEnough = _poseOk && _stabilityScore >= 0.5;
        final stableToStartCountdown = _poseOk && _stabilityScore >= 0.65;

        if (_countdown != null) {
          if (stableEnough) {
            _countdownWeakFrames = 0;
          } else {
            _countdownWeakFrames += 1;
            if (_countdownWeakFrames >= 3) {
              _cancelCountdown();
              await _speak('Stabilite perdue. Reprenez la position.', force: true);
            }
          }
        } else if (stableToStartCountdown) {
          _startCountdownIfNeeded();
        } else {
          await _speak(instruction);
        }
      } else if (!_poseOk) {
        _cancelCountdown();
        await _speak('Pose non stable. Reprenez la position.', force: true);
      }
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().replaceAll('Exception: ', '');
      final isTimeout = errorText.contains('Timeout');
      setState(() {
        _error = isTimeout
            ? 'Connexion lente: nouvelle tentative en cours...'
            : errorText;
      });
      if (!isTimeout || confirmCapture) {
        _cancelCountdown();
      }
    } finally {
      _isAnalyzing = false;
    }
  }

  List<int> _optimizeFrameBytes(List<int> bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final resized = decoded.width > 720
        ? img.copyResize(decoded, width: 720)
        : decoded;

    return img.encodeJpg(resized, quality: 72);
  }

  void _startCountdownIfNeeded() {
    if (_countdownTimer != null || _countdown != null) return;

    setState(() {
      _countdown = 3;
    });
    _countdownWeakFrames = 0;
    _speak('Position correcte. Capture dans trois.', force: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdownWeakFrames >= 3) {
        _cancelCountdown();
        await _speak('Pose trop instable. Repositionnez-vous.', force: true);
        return;
      }

      final current = _countdown;
      if (current == null) {
        _cancelCountdown();
        return;
      }

      if (current > 1) {
        final next = current - 1;
        setState(() {
          _countdown = next;
        });
        await _speak('$next', force: true);
        return;
      }

      _cancelCountdown();
      await _speak('Capture.', force: true);
      await _captureAndAnalyzeLiveFrame(confirmCapture: true);
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownWeakFrames = 0;
    if (_countdown != null && mounted) {
      setState(() {
        _countdown = null;
      });
    }
  }

  String _poseLabel(String pose) {
    switch (pose) {
      case 'front_relaxed':
        return 'Pose 1/3: Face camera';
      case 'left_profile':
        return 'Pose 2/3: Profil gauche';
      case 'right_profile':
        return 'Pose 3/3: Profil droit';
      default:
        return 'Pose en cours';
    }
  }

  @override
  void dispose() {
    _analyzeTimer?.cancel();
    _countdownTimer?.cancel();
    _tts.stop();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (!_hasVisionFeedback) {
      borderColor = const Color(0xFFE3E3E3);
    } else {
      borderColor = _poseOk && _stabilityScore >= 0.5
          ? Colors.green
          : Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mesure avec IA'),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _poseLabel(_currentPose),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _instruction,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: !_isCameraReady || _cameraController == null
                              ? const Center(
                                  child: Text(
                                    'Camera non disponible',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : CameraPreview(_cameraController!),
                        ),
                        if (_countdown != null)
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: const BoxDecoration(
                                  color: Color(0xAA000000),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _countdown.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _hasVisionFeedback
                        ? ((_poseOk && _stabilityScore >= 0.5)
                            ? 'Pose stable: cadre vert. Ne bougez plus.'
                            : 'Pose incorrecte: cadre rouge. Ajustez votre position.')
                        : 'Camera active - positionnez-vous dans le cadre.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (_hasVisionFeedback)
                    Text(
                      'Stabilite: ${(_stabilityScore * 100).round()}%',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
                    ),
                ],
              ),
      ),
    );
  }
}
