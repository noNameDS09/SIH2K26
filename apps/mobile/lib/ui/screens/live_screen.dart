import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import 'package:record/record.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _recording = false;
  bool _done = false;
  bool _detecting = false;
  String _error = '';
  String _question = 'What is this product called?';
  String _typedAnswer = '';
  String _lastTranscript = '';
  String _language = 'en-IN';
  String? _listingId;
  Map<String, dynamic> _session = {};
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final List<Uint8List> _chunks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SessionProvider>();
      _language = context.read<LocaleProvider>().locale.languageCode;
      _listingId = provider.listingId;
      _loadLive();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadLive() async {
    if (_listingId == null || _listingId!.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final listingResult = await ApiService.getListing(_listingId!);
      final result = await ApiService.catalogTurn(
        session: {},
        transcript: '',
        langCode: _language,
        cluster: (listingResult['cluster'] ?? listingResult['cluster_name'] ?? '').toString(),
      );
      setState(() {
        _loading = false;
        _question = result['question'] ?? 'What is this product called?';
        _done = result['done'] == true;
        _session = (result['session'] as Map<String, dynamic>?) ?? {};
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _startRecording() async {
    _chunks.clear();
    try {
      final has = await _recorder.hasPermission();
      if (!has) return;
      final stream = await _recorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
      _sub = stream.listen((chunk) => _chunks.add(Uint8List.fromList(chunk)));
      setState(() => _recording = true);
      Future.delayed(const Duration(seconds: 4), () => _stopRecording());
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    try { await _recorder.stop(); } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    setState(() => _recording = false);
    if (_chunks.isNotEmpty) {
      final wav = _buildWav(_chunks);
      setState(() => _detecting = true);
      final result = await ApiService.transcribeAudio(wav, 'hi-IN');
      setState(() => _detecting = false);
      setState(() {
        _lastTranscript = result.isNotEmpty ? result : '';
        _typedAnswer = result.isNotEmpty ? result : '';
      });
    }
  }

  static Uint8List _buildWav(List<Uint8List> chunks, {int sampleRate = 16000}) {
    final pcm = Uint8List.fromList(chunks.expand((c) => c).toList());
    final header = ByteData(44);
    void setStr(int o, String s) { for (int i = 0; i < s.length; i++) { header.setUint8(o + i, s.codeUnitAt(i)); } }
    setStr(0, 'RIFF'); header.setUint32(4, 36 + pcm.length, Endian.little);
    setStr(8, 'WAVE'); setStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); header.setUint16(20, 1, Endian.little); header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little); header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little); header.setUint16(34, 16, Endian.little);
    setStr(36, 'data'); header.setUint32(40, pcm.length, Endian.little);
    final r = Uint8List(44 + pcm.length); r.setRange(0, 44, header.buffer.asUint8List()); r.setRange(44, r.length, pcm); return r;
  }

  Future<void> _runLiveTurn(String transcript) async {
    if (transcript.trim().isEmpty || _listingId == null || _listingId!.isEmpty) return;
    setState(() => _busy = true);
    setState(() => _error = '');
    final result = await ApiService.catalogTurn(
      session: _session,
      transcript: transcript.trim(),
      langCode: _language,
      cluster: '',
    );
    final generated = result['listing'] as Map<String, dynamic>? ?? {};
    final mergedFields = <String, dynamic>{};
    final provider = context.read<SessionProvider>();
    // Persist fields merge
    try {
      final updated = await ApiService.patchListing(_listingId!, {
        'fields': result['fields'] ?? {},
        'title_en': (generated['title_en'] as String?) ?? '',
        'title_hi': (generated['title_hi'] as String?) ?? '',
        'desc_en': (generated['desc_en'] as String?) ?? '',
        'desc_hi': (generated['desc_hi'] as String?) ?? '',
      });
      if (mounted) provider.listing = updated;
    } catch (_) {}
    setState(() {
      _busy = false;
      _done = result['done'] == true;
      _session = (result['session'] as Map<String, dynamic>?) ?? {};
      _question = (result['question'] as String?) ?? 'What else should buyers know?';
      _lastTranscript = transcript.trim();
      _typedAnswer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stage indicator
              Row(
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF9F3C07), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('STAGE 3 — LIVE CATALOGER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9F3C07))),
                  const Spacer(),
                  Text('3 of 7', style: TextStyle(fontSize: 9, color: Color(0xFF705F58))),
                ],
              ),
              const SizedBox(height: 16),
              // Question
              Text("$_question", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // Voice recording button
              FilledButton(
                onPressed: _detecting ? null : (_recording ? _stopRecording : _startRecording),
                style: FilledButton.styleFrom(shape: StadiumBorder()),
                child: Text(_detecting ? 'Detecting…' : (_recording ? 'Stop recording' : 'Speak answer')),
              ),
              if (_lastTranscript.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Color(0xFFE7E1DD), borderRadius: BorderRadius.circular(8)), child: Text('Transcript: "$_lastTranscript"', style: TextStyle(fontSize: 11))),
              ],
              const SizedBox(height: 12),
              // Typed answer fallback
              TextField(
                controller: TextEditingController(text: _typedAnswer)..selection = TextSelection.collapsed(offset: _typedAnswer.length)..addListener(() { setState(() {}); }),
                decoration: InputDecoration(labelText: 'Your answer'),
                maxLines: 3,
                onChanged: (v) => setState(() => _typedAnswer = v),
                enabled: !_busy && !_recording,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _runLiveTurn(_typedAnswer),
                child: const Text('Save answer & next'),
              ),
              if (_done) ...[
                const SizedBox(height: 16),
                const Icon(Icons.check_circle, color: Color(0xFF476430)),
                const SizedBox(height: 8),
                const Text('Draft ready. Continue to Intelligence.'),
                const SizedBox(height: 8),
                FilledButton(onPressed: () => context.go('/intelligence'), child: const Text('Continue to Intelligence')),
              ],
              const Spacer(),
              if (_error.isNotEmpty) ...[
                Text(_error, style: TextStyle(color: Colors.red, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
