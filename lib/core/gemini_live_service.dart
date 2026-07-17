import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'audio_bridge.dart';
import 'camera_streamer.dart';
import 'jitter_buffer.dart';
import 'vad_detector.dart';

enum GeminiConnectionState { disconnected, connecting, connected, reconnecting, error }

class GeminiLiveService {
  final AudioBridge _audioBridge = AudioBridge();
  final VadDetector _vadDetector = VadDetector();
  final JitterBuffer _jitterBuffer = JitterBuffer();
  final CameraStreamer _cameraStreamer = CameraStreamer();

  WebSocketChannel? _wsChannel;
  GeminiConnectionState _connectionState = GeminiConnectionState.disconnected;
  String? _resumeHandle;
  String? _cachedSupabaseJwt;

  final _stateController = StreamController<GeminiConnectionState>.broadcast();
  final _inputTranscriptionController = StreamController<String>.broadcast();
  final _outputTranscriptionController = StreamController<String>.broadcast();
  final _interruptController = StreamController<void>.broadcast();

  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Uint8List>? _videoSub;
  StreamSubscription<Uint8List>? _jitterSub;

  GeminiLiveService() {
    _jitterSub = _jitterBuffer.playbackStream.listen((pcmChunk) {
      _audioBridge.writePcm(pcmChunk);
    });
  }

  Stream<GeminiConnectionState> get connectionState => _stateController.stream;
  Stream<String> get inputTranscriptions => _inputTranscriptionController.stream;
  Stream<String> get outputTranscriptions => _outputTranscriptionController.stream;
  Stream<void> get interrupts => _interruptController.stream;
  bool get isConnected => _connectionState == GeminiConnectionState.connected;

  Future<void> connect({required String supabaseJwt}) async {
    if (_connectionState == GeminiConnectionState.connected) return;
    _cachedSupabaseJwt = supabaseJwt;
    _updateState(GeminiConnectionState.connecting);

    try {
      final tokenData = await _fetchEphemeralToken(supabaseJwt);
      final String token = tokenData['token'];
      await _establishWebSocket(token);
    } catch (e) {
      _updateState(GeminiConnectionState.error);
      rethrow;
    }
  }

  Future<void> _reconnect() async {
    if (_resumeHandle == null) return;
    _updateState(GeminiConnectionState.reconnecting);

    try {
      await _establishWebSocket(null, resumeHandle: _resumeHandle);
    } catch (e) {
      print('Session resumption failed, performing clean connect...');
      _resumeHandle = null;
      if (_cachedSupabaseJwt != null) {
        connect(supabaseJwt: _cachedSupabaseJwt!);
      } else {
        _updateState(GeminiConnectionState.disconnected);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchEphemeralToken(String jwt) async {
    final supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final tokenFunction = dotenv.env['GEMINI_TOKEN_FUNCTION'] ?? 'gemini-token';
    final url = Uri.parse('$supabaseUrl/functions/v1/$tokenFunction');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('Failed to fetch ephemeral token: ${response.body}', uri: url);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _establishWebSocket(String? token, {String? resumeHandle}) async {
    String urlStr = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';
    if (resumeHandle != null) {
      urlStr += '?session_resumption_handle=$resumeHandle';
    } else if (token != null) {
      urlStr += '?access_token=$token';
    } else {
      throw ArgumentError('Either token or resumeHandle must be provided.');
    }

    final uri = Uri.parse(urlStr);
    _wsChannel = WebSocketChannel.connect(uri);

    _wsChannel!.stream.listen(
      (message) => _handleIncomingMessage(message),
      onError: (err) {
        print('Gemini WS error: $err');
        _handleDisconnect();
      },
      onDone: () {
        _handleDisconnect();
      },
    );

    await _audioBridge.initSpeaker();

    if (resumeHandle == null) {
      _sendSetupHandshake();
    }

    _updateState(GeminiConnectionState.connected);
  }

  void _sendSetupHandshake() {
    final setupMsg = {
      'setup': {
        'model': 'models/gemini-3.1-flash-live-preview',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
        },
        'systemInstruction': {
          'parts': [{'text': 'You are Quacky, an earthquake emergency agent inside a safety app. See surrounding area and help user.'}]
        },
        'inputAudioTranscription': {},
        'outputAudioTranscription': {},
        'sessionResumption': {},
      }
    };
    _wsChannel?.sink.add(jsonEncode(setupMsg));
  }

  void _handleIncomingMessage(dynamic message) {
    if (message is! String) return;

    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      if (data.containsKey('sessionResumptionUpdate')) {
        _resumeHandle = data['sessionResumptionUpdate']['newHandle'] as String?;
      }

      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'] as Map<String, dynamic>;

        if (serverContent['interrupted'] == true) {
          _performLocalInterrupt();
        }

        if (serverContent.containsKey('inputTranscription')) {
          final userText = serverContent['inputTranscription']['text'] as String?;
          if (userText != null) {
            _inputTranscriptionController.add(userText);
          }
        }

        if (serverContent.containsKey('outputTranscription')) {
          final aiText = serverContent['outputTranscription']['text'] as String?;
          if (aiText != null) {
            _outputTranscriptionController.add(aiText);
          }
        }

        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
          final parts = modelTurn['parts'] as List<dynamic>?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map<String, dynamic> && part.containsKey('inlineData')) {
                final inlineData = part['inlineData'] as Map<String, dynamic>;
                final base64Pcm = inlineData['data'] as String?;
                if (base64Pcm != null) {
                  final pcmBytes = base64Decode(base64Pcm);
                  _jitterBuffer.push(pcmBytes);
                }
              }
            }
          }
        }
      }

      if (data.containsKey('goAway')) {
        _reconnect();
      }
    } catch (e) {
      print('Error parsing Gemini message: $e');
    }
  }

  void _performLocalInterrupt() {
    _jitterBuffer.flush();
    _audioBridge.flushSpeaker();
    _interruptController.add(null);
  }

  void _handleDisconnect() {
    _wsChannel = null;
    if (_resumeHandle != null) {
      _reconnect();
    } else {
      _updateState(GeminiConnectionState.disconnected);
    }
  }


  Future<void> startAudioStream() async {
    if (_micSub != null) return;

    final micStream = _audioBridge.startMic();
    _micSub = micStream.listen((pcmChunk) {
      final isSpeaking = _vadDetector.process(pcmChunk);

      if (isSpeaking && _jitterBuffer.currentDepth > 0) {
        _performLocalInterrupt();
        sendAudioStreamEnd();
      }

      if (_connectionState == GeminiConnectionState.connected) {
        final base64Pcm = base64Encode(pcmChunk);
        final audioInputMsg = {
          'realtimeInput': {
            'mediaChunks': [
              {
                'mimeType': 'audio/pcm;rate=16000',
                'data': base64Pcm,
              }
            ]
          }
        };
        _wsChannel?.sink.add(jsonEncode(audioInputMsg));
      }
    });
  }

  Future<void> stopAudioStream() async {
    await _micSub?.cancel();
    _micSub = null;
    await _audioBridge.stopMic();
  }

  void sendAudioStreamEnd() {
    if (_connectionState != GeminiConnectionState.connected) return;
    final msg = {
      'realtimeInput': {
        'audioStreamEnd': true,
      }
    };
    _wsChannel?.sink.add(jsonEncode(msg));
  }

  Future<void> startVideoStream() async {
    if (_videoSub != null) return;

    await _cameraStreamer.initialize();
    _cameraStreamer.startStreaming();

    _videoSub = _cameraStreamer.frames.listen((jpegBytes) {
      if (_connectionState == GeminiConnectionState.connected) {
        final base64Jpeg = base64Encode(jpegBytes);
        final videoInputMsg = {
          'realtimeInput': {
            'mediaChunks': [
              {
                'mimeType': 'image/jpeg',
                'data': base64Jpeg,
              }
            ]
          }
        };
        _wsChannel?.sink.add(jsonEncode(videoInputMsg));
      }
    });
  }

  Future<void> stopVideoStream() async {
    await _videoSub?.cancel();
    _videoSub = null;
    _cameraStreamer.stopStreaming();
    await _cameraStreamer.dispose();
  }

  void _updateState(GeminiConnectionState newState) {
    _connectionState = newState;
    _stateController.add(newState);
  }

  Future<void> close() async {
    _resumeHandle = null;
    _updateState(GeminiConnectionState.disconnected);

    await stopAudioStream();
    await stopVideoStream();

    _jitterBuffer.flush();
    await _audioBridge.disposeSpeaker();

    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void dispose() {
    close();
    _stateController.close();
    _inputTranscriptionController.close();
    _outputTranscriptionController.close();
    _interruptController.close();
    _jitterSub?.cancel();
    _audioBridge.dispose();
    _vadDetector.dispose();
    _jitterBuffer.dispose();
  }
}

class HttpException implements Exception {
  final String message;
  final Uri uri;
  HttpException(this.message, {required this.uri});
  @override
  String toString() => 'HttpException: $message at $uri';
}
