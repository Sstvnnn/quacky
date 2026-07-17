import 'dart:async';
import 'package:flutter/services.dart';

class AudioBridge {
  static const MethodChannel _methods = MethodChannel('quacky/audio/methods');
  static const EventChannel _micEvent = EventChannel('quacky/audio/mic');
  static const MethodChannel _speakerMethods = MethodChannel('quacky/audio/speaker');

  StreamSubscription<dynamic>? _micSubscription;
  final _micController = StreamController<Uint8List>.broadcast();


  Stream<Uint8List> startMic() {
    if (_micSubscription != null) {
      return _micController.stream;
    }

    _methods.invokeMethod('startRecording').then((_) {
      _micSubscription = _micEvent.receiveBroadcastStream().listen(
        (data) {
          if (data is Uint8List) {
            _micController.add(data);
          }
        },
        onError: (err) {
          _micController.addError(err);
        },
      );
    }).catchError((err) {
      _micController.addError(err);
    });

    return _micController.stream;
  }

  Future<void> stopMic() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    try {
      await _methods.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print('Error stopping mic recording: ${e.message}');
    }
  }

  Future<bool> get isAecAvailable async {
    try {
      final bool? available = await _methods.invokeMethod('isAecAvailable');
      return available ?? false;
    } on PlatformException {
      return false;
    }
  }


  Future<void> initSpeaker() async {
    try {
      await _speakerMethods.invokeMethod('initSpeaker');
    } on PlatformException catch (e) {
      throw StateError('Failed to initialize native speaker: ${e.message}');
    }
  }

  Future<void> writePcm(Uint8List pcmChunk) async {
    try {
      await _speakerMethods.invokeMethod('writePcm', {'data': pcmChunk});
    } on PlatformException catch (e) {
      print('Error playing audio chunk: ${e.message}');
    }
  }

  Future<void> flushSpeaker() async {
    try {
      await _speakerMethods.invokeMethod('flushSpeaker');
    } on PlatformException catch (e) {
      print('Error flushing speaker buffer: ${e.message}');
    }
  }

  Future<void> disposeSpeaker() async {
    try {
      await _speakerMethods.invokeMethod('disposeSpeaker');
    } on PlatformException catch (e) {
      print('Error disposing speaker: ${e.message}');
    }
  }

  void dispose() {
    stopMic();
    disposeSpeaker();
    _micController.close();
  }
}
