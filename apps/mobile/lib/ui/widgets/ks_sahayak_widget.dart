import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import '../l10n/locale_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

enum _VoiceState { idle, recording, processing, speaking, error }

class KsSahayakWidget extends StatefulWidget {
  const KsSahayakWidget({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KsSahayakWidget(),
    );
  }

  @override
  State<KsSahayakWidget> createState() => _KsSahayakWidgetState();
}

class _KsSahayakWidgetState extends State<KsSahayakWidget> {
  _VoiceState _state = _VoiceState.idle;
  String? _transcript;
  String? _response;
  String? _errorMessage;

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
    if (_state != _VoiceState.idle) return;
    setState(() { _state = _VoiceState.recording; _transcript = null; _response = null; });
    final provider = context.read<SessionProvider>();
    await provider.startRecording();
  }

  Future<void> _stopAndProcess() async {
    if (_state != _VoiceState.recording) return;
    setState(() => _state = _VoiceState.processing);
    final provider = context.read<SessionProvider>();
    final langCode = _sarvamCode(context);
    final listingId = provider.listingId;

    try {
      await provider.stopRecordingAndSubmit(langCode: langCode);
      final transcript = provider.lastTranscript ?? '';
      setState(() => _transcript = transcript);

      // Call voiceAction endpoint
      final result = await ApiService.voiceAction(
        transcript: transcript,
        languageCode: langCode,
        listingId: listingId,
      );

      final responseText = result?['response'] as String? ?? result?['text'] as String?;
      if (responseText != null && responseText.isNotEmpty) {
        setState(() { _state = _VoiceState.speaking; _response = responseText; });
        await provider.speakText(responseText, langCode: langCode);
        if (mounted) setState(() => _state = _VoiceState.idle);
      } else {
        // Fall back to queryAssistant
        final qaResult = await ApiService.queryAssistant(
          query: transcript,
          langCode: langCode,
          listingId: listingId,
        );
        final qaText = qaResult?['answer'] as String? ?? 'मला माफ करा, मी समजू शकलो नाही.';
        if (!mounted) return;
        setState(() { _state = _VoiceState.speaking; _response = qaText; });
        await provider.speakText(qaText, langCode: langCode);
        if (mounted) setState(() => _state = _VoiceState.idle);
      }
    } catch (e) {
      if (mounted) setState(() { _state = _VoiceState.error; _errorMessage = e.toString(); });
    }
  }

  void _reset() => setState(() {
    _state = _VoiceState.idle;
    _transcript = null;
    _response = null;
    _errorMessage = null;
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KsColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KsColors.terracotta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: KsColors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sahayak', style: KsTextStyles.h3),
                  Text('AI Voice Assistant',
                      style: KsTextStyles.caption.copyWith(color: KsColors.textSecondary)),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: KsColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // State display
          if (_state == _VoiceState.idle && _transcript == null) ...[
            _IdleHint(),
          ] else if (_state == _VoiceState.recording) ...[
            _RecordingAnimation(),
          ] else if (_state == _VoiceState.processing) ...[
            _ProcessingIndicator(),
          ] else if (_state == _VoiceState.error) ...[
            _ErrorCard(message: _errorMessage, onRetry: _reset),
          ] else ...[
            if (_transcript != null) ...[
              _BubbleCard(text: _transcript!, isUser: true),
              const SizedBox(height: 8),
            ],
            if (_response != null) ...[
              _BubbleCard(text: _response!, isUser: false),
            ] else if (_state == _VoiceState.speaking) ...[
              const Center(child: CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2)),
            ],
          ],

          const SizedBox(height: 24),

          // Mic button
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _state == _VoiceState.recording ? _stopAndProcess : _startRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _state == _VoiceState.recording ? KsColors.terracotta : KsColors.surface1,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _state == _VoiceState.recording ? KsColors.terracotta : KsColors.border,
                        width: _state == _VoiceState.recording ? 2.5 : 1.5,
                      ),
                      boxShadow: _state == _VoiceState.recording
                          ? [BoxShadow(color: KsColors.terracotta.withAlpha(77), blurRadius: 16, spreadRadius: 2)]
                          : null,
                    ),
                    child: Icon(
                      _state == _VoiceState.recording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 32,
                      color: _state == _VoiceState.recording ? KsColors.white : KsColors.terracotta,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _state == _VoiceState.recording
                      ? 'Listening… tap to stop'
                      : _state == _VoiceState.processing
                          ? 'Processing…'
                          : 'Ask Sahayak anything',
                  style: KsTextStyles.body(
                    color: _state == _VoiceState.recording
                        ? KsColors.terracotta
                        : KsColors.textSecondary,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try asking:',
              style: KsTextStyles.label(color: KsColors.textSecondary, size: 10)),
          const SizedBox(height: 8),
          ...const [
            'माझी किंमत बरोबर आहे का?',
            'सध्या बाजारात काय ट्रेंड आहे?',
            'ONDC वर कसे लिस्ट करायचे?',
          ].map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.chevron_right, size: 14, color: KsColors.terracotta),
              const SizedBox(width: 4),
              Text(q, style: KsTextStyles.body(size: 12)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _RecordingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KsColors.peach3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.graphic_eq, color: KsColors.terracotta, size: 24),
        const SizedBox(width: 12),
        Text('Listening…', style: KsTextStyles.bodyMedium(size: 13)),
      ]),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text('Sahayak is thinking…', style: KsTextStyles.body(size: 13)),
      ]),
    );
  }
}

class _BubbleCard extends StatelessWidget {
  final String text;
  final bool isUser;
  const _BubbleCard({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUser ? KsColors.peach3 : KsColors.surface1,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isUser ? 14 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 14),
        ),
        border: isUser ? null : Border.all(color: KsColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Icon(Icons.auto_awesome, size: 14, color: KsColors.terracotta),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(text, style: KsTextStyles.body(size: 13))),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorCard({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.peach3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Something went wrong', style: KsTextStyles.bodyMedium()),
          if (message != null) Text(message!, style: KsTextStyles.caption),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
