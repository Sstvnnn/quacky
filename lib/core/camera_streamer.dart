import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraStreamer {
  final int targetFps;
  final ResolutionPreset resolution;

  CameraController? _controller;
  bool _isInitialized = false;
  Timer? _captureTimer;
  final _frameController = StreamController<Uint8List>.broadcast();

  CameraStreamer({
    this.targetFps = 1,
    this.resolution = ResolutionPreset.low,
  });

  Stream<Uint8List> get frames => _frameController.stream;
  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No cameras available on this device.');
      }

      final selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _frameController.addError(e);
      rethrow;
    }
  }

  void startStreaming() {
    if (!_isInitialized || _controller == null) return;

    _captureTimer?.cancel();
    final intervalMs = (1000 / targetFps).round();

    _captureTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
        return;
      }

      try {
        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        _frameController.add(bytes);
      } catch (e) {
        print('Camera capture error: $e');
      }
    });
  }

  void stopStreaming() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  Widget get previewWidget {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return CameraPreview(_controller!);
  }

  Future<void> dispose() async {
    stopStreaming();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _frameController.close();
  }
}
