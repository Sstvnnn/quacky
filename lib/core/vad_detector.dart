import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

class VadDetector {
  final double onsetThresholdDb;
  final double offsetThresholdDb;
  final int hangoverFrames;

  bool _isSpeaking = false;
  int _silenceFrameCount = 0;

  final _speakingController = StreamController<bool>.broadcast();

  VadDetector({
    this.onsetThresholdDb = -26.0,
    this.offsetThresholdDb = -32.0,
    this.hangoverFrames = 4,
  });

  Stream<bool> get isSpeakingStream => _speakingController.stream;
  bool get isSpeaking => _isSpeaking;

  bool process(Uint8List pcmChunk) {
    if (pcmChunk.isEmpty) return _isSpeaking;

    final db = calculateRmsDb(pcmChunk);

    if (db > onsetThresholdDb) {
      _silenceFrameCount = 0;
      if (!_isSpeaking) {
        _isSpeaking = true;
        _speakingController.add(true);
      }
    } else if (db < offsetThresholdDb) {
      if (_isSpeaking) {
        _silenceFrameCount++;
        if (_silenceFrameCount >= hangoverFrames) {
          _isSpeaking = false;
          _silenceFrameCount = 0;
          _speakingController.add(false);
        }
      }
    } else {
      if (_isSpeaking) {
        _silenceFrameCount = 0;
      }
    }

    return _isSpeaking;
  }

  static double calculateRmsDb(Uint8List pcmChunk) {
    if (pcmChunk.isEmpty) return -100.0;

    final buffer = pcmChunk.buffer;
    final int16List = Int16List.view(
      buffer,
      pcmChunk.offsetInBytes,
      pcmChunk.lengthInBytes ~/ 2,
    );

    double sumSq = 0.0;
    for (int i = 0; i < int16List.length; i++) {
      final sample = int16List[i].toDouble();
      sumSq += sample * sample;
    }

    final double meanSq = sumSq / int16List.length;
    final double rms = sqrt(meanSq);

    if (rms < 0.0001) {
      return -100.0;
    }

    final double db = 20 * (log(rms / 32768.0) / ln10);
    return db;
  }

  void dispose() {
    _speakingController.close();
  }
}
