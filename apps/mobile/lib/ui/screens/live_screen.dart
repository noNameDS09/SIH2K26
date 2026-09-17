import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import 'package:record/record.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';

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
  String _language = 'en-IN';
  String? _listingId;
  Map<String, dynamic> _session = {};
  Map<String, dynamic>? _listing;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final List<Uint8List> _chunks = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _answerCtrl = TextEditingController();
  bool _playingQuestion = false;
  final AudioPlayer _questionPlayer = AudioPlayer();

  // Answered fields history for display
  final List<_AnsweredField> _answeredFields = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SessionProvider>();
      _language = context.read<LocaleProvider>().locale.languageCode;
      // Map locale code to Sarvam-style code
      const langMap = {
        'en': 'en-IN', 'hi': 'hi-IN', 'mr': 'mr-IN', 'ta': 'ta-IN',
        'te': 'te-IN', 'kn': 'kn-IN', 'bn': 'bn-IN', 'gu': 'gu-IN',
      };
      _language = langMap[_language] ?? 'hi-IN';
      _listingId = provider.listingId;
      _loadLive();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    _scrollCtrl.dispose();
    _answerCtrl.dispose();
    _questionPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLive() async {
    if (_listingId == null || _listingId!.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final listingResult = await ApiService.getListing(_listingId!);
      _listing = listingResult;

      // Pre-populate answered fields from existing listing data
      final fields = (listingResult['fields'] as Map<String, dynamic>?) ?? {};
      for (final entry in fields.entries) {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
          _answeredFields.add(_AnsweredField(
            question: _fieldLabel(entry.key),
            answer: entry.value.toString(),
          ));
        }
      }

      final result = await ApiService.catalogTurn(
        session: {},
        transcript: '',
        langCode: _language,
        cluster: (listingResult['cluster'] ?? listingResult['cluster_name'] ?? '').toString(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _question = result['question'] ?? 'What is this product called?';
          _done = result['done'] == true;
          _session = (result['session'] as Map<String, dynamic>?) ?? {};
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fieldLabel(String key) {
    const labels = {
      'craft': 'Craft', 'material': 'Material', 'technique': 'Technique',
      'colour': 'Colour', 'occasion': 'Occasion', 'gi': 'GI status',
      'hours': 'Hours of work', 'material_cost_inr': 'Material cost',
      'material_source': 'Material source', 'effort': 'Effort',
      'title_en': 'English title', 'title_hi': 'Hindi title',
      'desc_en': 'English description', 'desc_hi': 'Hindi description',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  Future<void> _startRecording() async {
    _chunks.clear();
    try {
      final has = await _recorder.hasPermission();
      if (!has) {
        setState(() => _error = 'Microphone permission is required for voice input.');
        return;
      }
      final stream = await _recorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
      _sub = stream.listen((chunk) => _chunks.add(Uint8List.fromList(chunk)));
      setState(() { _recording = true; _error = ''; });
    } catch (_) {
      setState(() => _error = 'Could not start recording. Use the text input instead.');
    }
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
      try {
        final result = await ApiService.transcribeAudio(wav, _language);
        if (mounted) {
          setState(() => _detecting = false);
          if (result.isNotEmpty) {
            _answerCtrl.text = result;
            setState(() => _typedAnswer = result);
          } else {
            setState(() => _error = 'Could not hear an answer. Speak a little longer or type below.');
          }
        }
      } catch (_) {
        if (mounted) setState(() { _detecting = false; _error = 'Transcription failed.'; });
      }
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

  Future<void> _submitAnswer(String transcript) async {
    if (transcript.trim().isEmpty || _listingId == null || _listingId!.isEmpty) return;
    setState(() { _busy = true; _error = ''; });
    try {
      final result = await ApiService.catalogTurn(
        session: _session,
        transcript: transcript.trim(),
        langCode: _language,
        cluster: (_listing?['cluster'] ?? '').toString(),
      );
      final generated = result['listing'] as Map<String, dynamic>? ?? {};

      // Persist to backend
      try {
        final updated = await ApiService.patchListing(_listingId!, {
          'fields': result['fields'] ?? {},
          'title_en': (generated['title_en'] as String?) ?? '',
          'title_hi': (generated['title_hi'] as String?) ?? '',
          'desc_en': (generated['desc_en'] as String?) ?? '',
          'desc_hi': (generated['desc_hi'] as String?) ?? '',
        });
        if (mounted) context.read<SessionProvider>().listing = updated;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _answeredFields.add(_AnsweredField(question: _question, answer: transcript.trim()));
          _busy = false;
          _done = result['done'] == true;
          _session = (result['session'] as Map<String, dynamic>?) ?? {};
          _question = (result['question'] as String?) ?? (_done ? 'Your draft is ready to review.' : 'What else should buyers know?');
          _typedAnswer = '';
          _answerCtrl.clear();
        });
        // Scroll to bottom to show new question
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'The cataloger could not continue. Try again.'; });
    }
  }

  Future<void> _speakQuestion() async {
    if (_playingQuestion) {
      await _questionPlayer.stop();
      if (mounted) setState(() => _playingQuestion = false);
      return;
    }
    setState(() => _playingQuestion = true);
    try {
      final bytes = await ApiService.synthesizeSpeech(_question, _language);
      if (bytes != null && mounted) {
        await _questionPlayer.play(BytesSource(bytes));
        _questionPlayer.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _playingQuestion = false);
        });
      } else {
        if (mounted) setState(() => _playingQuestion = false);
      }
    } catch (_) {
      if (mounted) setState(() => _playingQuestion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(
        title: 'Step 3 · Describe',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2.5))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_listingId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: KsColors.textMuted),
              const SizedBox(height: 16),
              Text('Start with a product photo', style: KsTextStyles.section),
              const SizedBox(height: 8),
              Text('The live cataloger needs a product draft before it can save your answers.', textAlign: TextAlign.center, style: KsTextStyles.body()),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/capture'),
                style: FilledButton.styleFrom(backgroundColor: KsColors.terracotta),
                child: const Text('Capture product'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KsProgressBar(totalSteps: 7, currentStep: 3, label: 'STAGE 3 — LIVE CATALOGER'),
                const SizedBox(height: 20),

                Text('Tell the product story', style: KsTextStyles.editorial(size: 22)),
                const SizedBox(height: 6),
                Text('Answer each question by voice or text. Your answers build the product draft.', style: KsTextStyles.body()),
                const SizedBox(height: 4),

                // Fields collected counter
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _done ? KsColors.greenSoft : KsColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_done ? Icons.check_circle_outline : Icons.edit_note_outlined,
                          size: 18, color: _done ? KsColors.green : KsColors.terracotta),
                      const SizedBox(width: 8),
                      Text('${_answeredFields.length} fields collected',
                          style: KsTextStyles.bodyMedium(color: _done ? KsColors.green : KsColors.ink)),
                      if (_done) ...[
                        const Spacer(),
                        Text('Draft ready', style: KsTextStyles.label(color: KsColors.green, size: 10)),
                      ],
                    ],
                  ),
                ),

                // Previously answered questions
                ..._answeredFields.map((field) => _AnsweredCard(field: field)),

                // Current question (only if not done)
                if (!_done) ...[
                  const SizedBox(height: 8),
                  // Current question card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KsColors.terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text('KalaSetu asks', style: KsTextStyles.label(color: KsColors.terracotta)),
                            ),
                            GestureDetector(
                              onTap: _busy ? null : _speakQuestion,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _playingQuestion
                                      ? KsColors.terracottaSoft
                                      : KsColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _playingQuestion
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  size: 20,
                                  color: KsColors.terracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_question, style: KsTextStyles.editorial(size: 18)),
                        const SizedBox(height: 16),

                        // Voice record button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : (_detecting ? null : (_recording ? _stopRecording : _startRecording)),
                            icon: Icon(_recording ? Icons.stop_rounded : (_detecting ? Icons.hearing : Icons.mic_none_rounded)),
                            label: Text(_detecting ? 'Transcribing…' : (_recording ? 'Stop & transcribe' : 'Speak answer')),
                            style: FilledButton.styleFrom(
                              backgroundColor: _recording ? Colors.red.shade700 : KsColors.terracotta,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: KsColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or type', style: KsTextStyles.caption),
                            ),
                            const Expanded(child: Divider(color: KsColors.border)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Typed answer
                        TextField(
                          controller: _answerCtrl,
                          maxLines: 3,
                          style: KsTextStyles.body(color: KsColors.ink),
                          onChanged: (v) => setState(() => _typedAnswer = v),
                          enabled: !_busy && !_recording,
                          decoration: InputDecoration(
                            hintText: 'Type what you would say…',
                            hintStyle: KsTextStyles.body(),
                            filled: true,
                            fillColor: KsColors.surfaceWarm,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_busy || _typedAnswer.trim().isEmpty) ? null : () => _submitAnswer(_typedAnswer),
                            icon: _busy
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: Text(_busy ? 'Saving…' : 'Save answer & next'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: KsColors.terracotta),
                              foregroundColor: KsColors.terracotta,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error, style: KsTextStyles.caption.copyWith(color: Colors.red.shade700))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: KsColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/studio'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KsColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Back', style: KsTextStyles.bodyMedium(color: KsColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _done ? () => context.push('/intelligence') : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Review draft'),
                    style: FilledButton.styleFrom(
                      backgroundColor: KsColors.terracotta,
                      disabledBackgroundColor: KsColors.terracotta.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnsweredField {
  final String question;
  final String answer;
  const _AnsweredField({required this.question, required this.answer});
}

class _AnsweredCard extends StatelessWidget {
  const _AnsweredCard({required this.field});
  final _AnsweredField field;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KsColors.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: KsColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.question, style: KsTextStyles.label(color: KsColors.textSecondary)),
                const SizedBox(height: 4),
                Text(field.answer, style: KsTextStyles.body(color: KsColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
