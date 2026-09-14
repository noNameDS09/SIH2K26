import 'dart:async';
// dart:typed_data re-exported via flutter/foundation
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'api_service.dart';

class SessionProvider extends ChangeNotifier {
  // ── Auth ──────────────────────────────────────────────────────────────────
  bool isAuthenticated = false;

  // ── Catalog session ───────────────────────────────────────────────────────
  Map<String, dynamic> _session = {};
  String? currentQuestion;
  String? lastTranscript;
  bool isDone = false;
  Map<String, dynamic>? listing;
  List<dynamic>? table;

  Map<String, dynamic> get session => _session;

  // ── Recording ─────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isRecording = false;
  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  final AudioRecorder _recorder = AudioRecorder();
  final List<Uint8List> _pcmChunks = [];
  StreamSubscription<Uint8List>? _recordSub;

  // ── Playback ──────────────────────────────────────────────────────────────
  bool isPlayingAudio = false;
  final AudioPlayer _player = AudioPlayer();

  // ── Image ──────────────────────────────────────────────────────────────────
  Uint8List? capturedImageBytes;
  Uint8List? enhancedImageBytes;
  bool isEnhancing = false;

  SessionProvider() {
    _player.onPlayerStateChanged.listen((state) {
      isPlayingAudio = state == PlayerState.playing;
      notifyListeners();
    });
  }

  // ── Init: auth + first catalog question ──────────────────────────────────

  Future<void> init() async {
    if (isAuthenticated && currentQuestion != null) return;
    _setLoading(true, 'कनेक्ट करत आहे…');
    isAuthenticated = await ApiService.authenticate();
    final result = await ApiService.catalogTurn(session: {});
    _applyTurnResult(result);
    _setLoading(false, null);
  }

  // ── Recording lifecycle ───────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (isRecording || isLoading) return;
    _pcmChunks.clear();
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _setStatus('माइक परवानगी नाही');
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _recordSub = stream.listen(
        (chunk) => _pcmChunks.add(Uint8List.fromList(chunk)),
        onError: (_) {},
      );
      isRecording = true;
      notifyListeners();
    } catch (_) {
      isRecording = true; // allow toggle even if real recording fails
      notifyListeners();
    }
  }

  Future<void> stopRecordingAndSubmit({String langCode = 'mr-IN'}) async {
    if (!isRecording) return;
    isRecording = false;
    _setLoading(true, 'ऐकत आहे…');

    try {
      await _recorder.stop();
    } catch (_) {}
    await _recordSub?.cancel();
    _recordSub = null;

    String transcript = '';
    if (_pcmChunks.isNotEmpty) {
      final wav = _buildWav(_pcmChunks);
      _setStatus('उलट अनुवाद करत आहे…');
      transcript = await ApiService.transcribeAudio(wav, langCode);
    }

    // If STT returned nothing, use a placeholder that advances the cataloger
    if (transcript.isEmpty) transcript = 'हो';

    lastTranscript = transcript;
    _setStatus('माहिती नोंदवत आहे…');
    final result =
        await ApiService.catalogTurn(session: _session, transcript: transcript);
    _applyTurnResult(result);
    _setLoading(false, null);
  }

  // ── TTS + audio playback ──────────────────────────────────────────────────

  Future<void> speakText(String text, {String langCode = 'mr-IN'}) async {
    if (isPlayingAudio) {
      await _player.stop();
      return;
    }
    final bytes = await ApiService.synthesizeSpeech(text, langCode);
    if (bytes != null) {
      await _player.play(BytesSource(bytes));
    }
  }

  // ── Image capture + enhance ───────────────────────────────────────────────

  Future<void> setCapturedImage(Uint8List bytes) async {
    capturedImageBytes = bytes;
    enhancedImageBytes = null;
    notifyListeners();
    _enhanceInBackground(bytes);
  }

  bool enhancedIsMock = false;

  Future<void> _enhanceInBackground(Uint8List bytes) async {
    isEnhancing = true;
    enhancedIsMock = false;
    notifyListeners();
    final listingId = 'listing-${DateTime.now().millisecondsSinceEpoch}';
    // Run API call and minimum animation time in parallel
    final results = await Future.wait([
      ApiService.enhanceImage(imageBytes: bytes, listingId: listingId),
      Future.delayed(const Duration(seconds: 3)),
    ]);
    final result = results[0] as Map<String, dynamic>?;
    isEnhancing = false;
    if (result != null) {
      final studioUrl = result['studio_url'] as String?;
      if (studioUrl != null) {
        final fetched = await ApiService.fetchBytes(studioUrl);
        enhancedImageBytes = fetched ?? bytes;
      } else {
        enhancedImageBytes = bytes;
      }
      enhancedIsMock = result['accepted'] != true;
    } else {
      // Backend offline — show original as placeholder, flag as mock
      enhancedImageBytes = bytes;
      enhancedIsMock = true;
    }
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    _session = {};
    currentQuestion = null;
    lastTranscript = null;
    isDone = false;
    listing = null;
    table = null;
    capturedImageBytes = null;
    enhancedImageBytes = null;
    ApiService.resetMock();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _applyTurnResult(Map<String, dynamic> result) {
    _session =
        (result['session'] as Map<String, dynamic>?) ?? _session;
    currentQuestion = result['speak'] as String?;
    isDone = result['done'] == true;
    if (isDone) {
      listing = result['listing'] as Map<String, dynamic>?;
      table = result['table'] as List<dynamic>?;
    }
  }

  void _setLoading(bool loading, String? status) {
    isLoading = loading;
    _statusMessage = status;
    notifyListeners();
  }

  void _setStatus(String? status) {
    _statusMessage = status;
    notifyListeners();
  }

  static Uint8List _buildWav(List<Uint8List> chunks,
      {int sampleRate = 16000}) {
    final pcm = Uint8List.fromList(chunks.expand((c) => c).toList());
    final header = ByteData(44);
    void setStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }
    setStr(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    setStr(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    final result = Uint8List(44 + pcm.length);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, result.length, pcm);
    return result;
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
