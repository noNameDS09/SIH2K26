import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_stage_progress.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _typedCtrl = TextEditingController();
  bool _showTyped = false;

  @override
  void initState() {
    super.initState();
    // Fetch the first question so the screen doesn't open with a blank
    // "Tell me about your craft…" placeholder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().startCatalogSession(langCode: KsStrings.sarvamLangCode(context));
    });
  }

  Future<void> _startRecording() async {
    final provider = context.read<SessionProvider>();
    await provider.startRecording();
  }

  Future<void> _stopAndSubmit() async {
    final provider = context.read<SessionProvider>();
    await provider.stopRecordingAndSubmit(langCode: KsStrings.sarvamLangCode(context));
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
    await provider.submitTypedText(text, langCode: KsStrings.sarvamLangCode(context));
    if (!mounted) return;
    if (provider.isDone) {
      context.go(AppRoutes.intelligence);
    }
  }

  /// Bypasses voice entirely for the confirm/reject step — the server
  /// only advances on an exact phrase match, and noisy STT transcripts
  /// ("haan, sahi hai") were falling through and re-asking the same slot.
  Future<void> _tapConfirm() async {
    final provider = context.read<SessionProvider>();
    await provider.confirmSlot(langCode: KsStrings.sarvamLangCode(context));
    if (!mounted) return;
    if (provider.isDone) context.go(AppRoutes.intelligence);
  }

  Future<void> _tapRedo() async {
    await context.read<SessionProvider>().rejectSlot(langCode: KsStrings.sarvamLangCode(context));
  }

  /// Manual escape hatch: force past a stuck question without relying on
  /// voice at all.
  Future<void> _skip() async {
    final provider = context.read<SessionProvider>();
    if (provider.isConfirmingSlot) {
      await _tapConfirm();
    } else {
      await provider.submitTypedText("don't know", langCode: KsStrings.sarvamLangCode(context));
      if (!mounted) return;
      if (provider.isDone) context.go(AppRoutes.intelligence);
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
                      const KsStageProgress(stage: 3, label: 'VOICE CATALOG'),
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
                        if (provider.isConfirmingSlot) ...[
                          // The server only advances on an exact phrase
                          // match ("theek hai"/"galat") — these buttons
                          // are the reliable path; voice still works too.
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _tapConfirm,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Correct'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KsColors.deepGreen,
                                    foregroundColor: KsColors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _tapRedo,
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Redo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: KsColors.terracotta,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        _MicButton(
                          isRecording: provider.isRecording,
                          onStart: _startRecording,
                          onStop: _stopAndSubmit,
                        ),
                        const SizedBox(height: 12),

                        // Manual escape hatch — force past a stuck
                        // question without relying on voice at all.
                        TextButton.icon(
                          onPressed: _skip,
                          icon: const Icon(Icons.skip_next_rounded, size: 16, color: KsColors.textSecondary),
                          label: Text(
                            'Skip / Next',
                            style: KsTextStyles.body(color: KsColors.textSecondary, size: 13),
                          ),
                        ),

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
