import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/mock_config.dart';
import 'profile_service.dart';

enum QuakePhase {
  idle,
  detecting, 
  consensus, 
  alarm, 
  geminiLive, 
  safe,
  sos,
}

class QuakeController extends ChangeNotifier {
  QuakePhase _phase = QuakePhase.idle;
  QuakePhase get phase => _phase;

  bool isDrill = false;
  int consensusVotes = 0;
  int countdown = MockConfig.geminiWindowSeconds;

  final List<String> captions = [];

  final AudioPlayer _siren = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  Timer? _stepTimer;
  Timer? _countdownTimer;
  Timer? _hapticTimer;
  final List<Timer> _scriptTimers = [];

  void _go(QuakePhase p) {
    _phase = p;
    notifyListeners();
  }

  void startEmergency({bool drill = false}) {
    _cancelTimers();
    isDrill = drill;
    consensusVotes = 0;
    countdown = MockConfig.geminiWindowSeconds;
    captions.clear();
    _go(QuakePhase.detecting);
    _stepTimer = Timer(const Duration(milliseconds: 2600), _startConsensus);
  }

  void _startConsensus() {
    _go(QuakePhase.consensus);
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      consensusVotes++;
      notifyListeners();
      if (consensusVotes >= MockConfig.consensusNeeded) {
        t.cancel();
        _stepTimer = Timer(const Duration(milliseconds: 600), _startAlarm);
      }
    });
  }

  Future<void> _startAlarm() async {
    _go(QuakePhase.alarm);
    _hapticTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => HapticFeedback.heavyImpact(),
    );
    try {
      await _siren.setReleaseMode(ReleaseMode.loop);
      await _siren.play(AssetSource(MockConfig.alarmAsset), volume: 1);
    } catch (_) {
    }
  }

  Future<void> acknowledgeAlarm() async {
    if (_phase != QuakePhase.alarm) return;
    _hapticTimer?.cancel();
    try {
      await _siren.stop();
    } catch (_) {}
    _startGeminiLive();
  }

  void _startGeminiLive() {
    _go(QuakePhase.geminiLive);

    for (final (sec, line) in MockConfig.geminiScript) {
      _scriptTimers.add(Timer(Duration(seconds: sec), () {
        if (_phase != QuakePhase.geminiLive) return;
        captions.add(line);
        notifyListeners();
        _speak(line);
      }));
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      notifyListeners();
      if (countdown <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _resolve(QuakePhase.sos);
      }
    });
  }

  void markSafe() {
    if (_phase != QuakePhase.geminiLive && _phase != QuakePhase.sos) return;
    _resolve(QuakePhase.safe);
  }

  void triggerSos() {
    if (_phase != QuakePhase.geminiLive) return;
    HapticFeedback.heavyImpact();
    _resolve(QuakePhase.sos);
  }

  void _resolve(QuakePhase result) {
    _cancelTimers();
    _tts.stop();
    _go(result);
    if (!isDrill) {
      ProfileService.setStatus(result == QuakePhase.sos ? 'sos' : 'safe')
          .catchError((_) {});
    }
  }

  Future<void> _speak(String text) async {
    if (MockConfig.mockTts) return;
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.speak(text);
    } catch (_) {}
  }

  void reset() {
    _cancelTimers();
    _siren.stop();
    _tts.stop();
    isDrill = false;
    _phase = QuakePhase.idle;
    notifyListeners();
  }

  void _cancelTimers() {
    _stepTimer?.cancel();
    _countdownTimer?.cancel();
    _hapticTimer?.cancel();
    for (final t in _scriptTimers) {
      t.cancel();
    }
    _scriptTimers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    _siren.dispose();
    _tts.stop();
    super.dispose();
  }
}
