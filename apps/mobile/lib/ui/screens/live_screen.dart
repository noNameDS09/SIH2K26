import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../l10n/locale_provider.dart';
import '../routes/app_routes.dart';
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
  final _typedCtrl = TextEditingController();
  bool _showTyped = false;

  String _sarvamCode(BuildContext context) {
    final lang = context.read<LocaleProvider>().locale.languageCode;
    const map = {
      'en': 'en-IN', 'hi': 'hi-IN', 'mr': 'mr-IN', 'ta': 'ta-IN',
      'te': 'te-IN', 'kn': 'kn-IN', 'bn': 'bn-IN', 'gu': 'gu-IN',
      'pa': 'pa-IN', 'ml': 'ml-IN', 'as': 'as-IN', 'or': 'od-IN',
    };
    return map[lang] ?? 'hi-IN';
  }

  Future<void> _startRecording() async {
    final provider = context.read<SessionProvider>();
    await provider.startRecording();
  }

  Future<void> _stopAndSubmit() async {
    final provider = context.read<SessionProvider>();
    await provider.stopRecordingAndSubmit(langCode: _sarvamCode(context));
    if (!mounted) return;
    if (provider.isDone) {
      context.go(AppRoutes.intelligence);
    }
  }

  Future<void> _submitTyped() async {
    final text = _typedCtrl.text.trim();
    if (text.isEmpty) return;
    _typedCtrl.clear();
    FocusScope.of(context).unfocus();
    final provider = context.read<SessionProvider>();
    provider.lastTranscript = text;
    // We manually call the catalog turn with typed text
    await provider.submitTypedText(text, langCode: _sarvamCode(context));
    if (!mounted) return;
    if (provider.isDone) {
      context.go(AppRoutes.intelligence);
    }
  }

  @override
  void dispose() {
    _typedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final isDone = provider.isDone;

        return Scaffold(
          backgroundColor: KsColors.background,
          body: Column(
            children: [
              KsAppHeader(
                title: 'Voice Q&A',
                onBack: () => context.go(AppRoutes.studio),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const KsProgressBar(
                        totalSteps: 7,
                        currentStep: 4,
                        label: 'STAGE 4 — VOICE CATALOG',
                      ),
                      const SizedBox(height: 20),

                      // Status / question display
                      if (provider.isLoading) ...[
                        _LoadingCard(message: provider.statusMessage ?? 'Processing…'),
                      ] else if (isDone) ...[
                        _DoneCard(onContinue: () => context.go(AppRoutes.intelligence)),
                      ] else ...[
                        _QuestionCard(question: provider.currentQuestion),
                        const SizedBox(height: 16),

                        // Transcript display
                        if (provider.lastTranscript != null) ...[
                          _TranscriptCard(text: provider.lastTranscript!),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // Voice record button
                      if (!isDone && !provider.isLoading) ...[
                        _MicButton(
                          isRecording: provider.isRecording,
                          onStart: _startRecording,
                          onStop: _stopAndSubmit,
                        ),
                        const SizedBox(height: 16),

                        // Typed fallback toggle
                        TextButton.icon(
                          onPressed: () => setState(() => _showTyped = !_showTyped),
                          icon: Icon(
                            _showTyped ? Icons.keyboard_hide : Icons.keyboard,
                            size: 16,
                            color: KsColors.textSecondary,
                          ),
                          label: Text(
                            _showTyped ? 'Hide keyboard' : 'Type instead',
                            style: KsTextStyles.body(color: KsColors.textSecondary, size: 13),
                          ),
                        ),

                        if (_showTyped) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _typedCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer…',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: KsColors.terracotta, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _submitTyped,
                                icon: const Icon(Icons.send_rounded, color: KsColors.terracotta),
                                style: IconButton.styleFrom(
                                  backgroundColor: KsColors.peach3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Step 4 of 7 — KalaSetu Voice Catalog',
                            style: KsTextStyles.caption,
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String? question;
  const _QuestionCard({this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KsColors.peach3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('CURRENT QUESTION',
                  style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question ?? 'Tell me about your craft…',
            style: KsTextStyles.h3.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String text;
  const _TranscriptCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.paleGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: KsColors.deepGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: KsTextStyles.body(size: 13)),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;
  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(message, style: KsTextStyles.body(color: KsColors.terracotta, size: 13)),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final VoidCallback onContinue;
  const _DoneCard({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KsColors.paleGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: KsColors.deepGreen),
          const SizedBox(height: 12),
          Text('All information recorded!',
              style: KsTextStyles.h3.copyWith(color: KsColors.deepGreen)),
          const SizedBox(height: 8),
          Text('Running AI Intelligence…',
              style: KsTextStyles.body(color: KsColors.textSecondary, size: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: KsColors.deepGreen,
              foregroundColor: KsColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View AI Intelligence'),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  const _MicButton({required this.isRecording, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: isRecording ? onStop : onStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isRecording ? KsColors.terracotta : KsColors.surface1,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRecording ? KsColors.terracotta : KsColors.border,
                  width: isRecording ? 3 : 1.5,
                ),
                boxShadow: isRecording
                    ? [BoxShadow(color: KsColors.terracotta.withAlpha(77), blurRadius: 20, spreadRadius: 4)]
                    : null,
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 36,
                color: isRecording ? KsColors.white : KsColors.terracotta,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isRecording ? 'Listening… tap to stop' : 'Tap to speak',
            style: KsTextStyles.body(
              color: isRecording ? KsColors.terracotta : KsColors.textSecondary,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}
