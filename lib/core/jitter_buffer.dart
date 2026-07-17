import 'dart:async';
import 'dart:typed_data';

class JitterBuffer {
  final int initialDepth;
  final int maxDepthMs;
  final int sampleRate;

  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  int _currentRequiredDepth;
  int _underrunCount = 0;

  Timer? _playbackTimer;
  final _playbackController = StreamController<Uint8List>.broadcast();

  JitterBuffer({
    this.initialDepth = 3,
    this.maxDepthMs = 200,
    this.sampleRate = 24000,
  }) : _currentRequiredDepth = initialDepth;

  Stream<Uint8List> get playbackStream => _playbackController.stream;
  int get underrunCount => _underrunCount;
  int get currentDepth => _queue.length;
  int get currentRequiredDepth => _currentRequiredDepth;

  void push(Uint8List chunk) {
    if (chunk.isEmpty) return;
    _queue.add(chunk);

    if (!_isPlaying && _queue.length >= _currentRequiredDepth) {
      _startPlayback();
    }
  }

  void flush() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _queue.clear();
    _isPlaying = false;
  }

  void _startPlayback() {
    _isPlaying = true;
    _processNext();
  }

  void _processNext() {
    if (!_isPlaying) return;

    if (_queue.isEmpty) {
      _underrunCount++;
      _isPlaying = false;
      _playbackTimer = null;

      final maxChunks = (maxDepthMs / 42.6).round();
      if (_currentRequiredDepth < maxChunks) {
        _currentRequiredDepth++;
      }
      return;
    }

    final chunk = _queue.removeAt(0);
    _playbackController.add(chunk);

    final samples = chunk.length ~/ 2;
    final durationMs = (samples / sampleRate) * 1000;

    _playbackTimer = Timer(
      Duration(microseconds: (durationMs * 1000).round()),
      _processNext,
    );

    if (_queue.length > _currentRequiredDepth && _currentRequiredDepth > initialDepth && _underrunCount % 10 == 0) {
      _currentRequiredDepth--;
    }
  }

  void dispose() {
    flush();
    _playbackController.close();
  }
}
