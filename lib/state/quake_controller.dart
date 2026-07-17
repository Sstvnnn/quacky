import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

enum LocationSource { aiSuggestion, userConfirmed }

class QuakeController extends ChangeNotifier {
  QuakePhase _phase = QuakePhase.idle;
  QuakePhase get phase => _phase;

  bool isDrill = false;
  int consensusVotes = 0;
  int countdown = MockConfig.geminiWindowSeconds;

  LocationSource locationSource = LocationSource.aiSuggestion;
  String locationNote = '';

  final AudioPlayer _siren = AudioPlayer();

  Timer? _stepTimer;
  Timer? _countdownTimer;
  Timer? _hapticTimer;

  void _go(QuakePhase p) {
    _phase = p;
    notifyListeners();
  }


  void startEmergency({bool drill = false}) {
    _cancelTimers();
    isDrill = drill;
    consensusVotes = 0;
    countdown = MockConfig.geminiWindowSeconds;
    locationSource = LocationSource.aiSuggestion;
    locationNote = '';
    _go(QuakePhase.detecting);
    _stepTimer = Timer(const Duration(milliseconds: 2800), _startConsensus);
  }

  void _startConsensus() {
    _go(QuakePhase.consensus);
    _stepTimer = Timer.periodic(const Duration(milliseconds: 45), (t) {
      consensusVotes += 1;
      notifyListeners();
      if (consensusVotes >= MockConfig.consensusReached) {
        t.cancel();
        _stepTimer = Timer(const Duration(milliseconds: 700), _startAlarm);
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


  void confirmLocationByVoice(String transcript) {
    locationSource = LocationSource.userConfirmed;
    locationNote = transcript;
    notifyListeners();
    if (!isDrill) {
      ProfileService.setLocation(
        source: 'user_confirmed',
        note: transcript,
      ).catchError((_) {});
    }
  }

  void _resolve(QuakePhase result) {
    _cancelTimers();
    _go(result);
    if (!isDrill) {
      ProfileService.setStatus(
        result == QuakePhase.sos ? 'sos' : 'safe',
      ).catchError((_) {});
    }
  }

  void reset() {
    _cancelTimers();
    _siren.stop();
    isDrill = false;
    _phase = QuakePhase.idle;
    notifyListeners();
  }

  void _cancelTimers() {
    _stepTimer?.cancel();
    _countdownTimer?.cancel();
    _hapticTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    _siren.dispose();
    super.dispose();
  }
}
