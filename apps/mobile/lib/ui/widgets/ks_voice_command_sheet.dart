import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// Header-mic bottom sheet. Replaces the old free-form "Sahayak" Q&A
/// assistant, which was a chatbot — banned by `00_AGENT_RULES.md` ("Do not
/// build a chatbot / blank prompt"). This sheet listens ONCE, matches only
/// the tiny voice grammar from `04_FEATURES_AND_SCREENS.md`
/// (theek hai/haan · galat/nahin · phir se · peeche · photo dobara ·
/// "daam" plus a number), executes that one action, and otherwise says it
/// did not understand. It never answers a free-form question.
enum _SheetState { idle, recording, processing, unrecognised }

class KsVoiceCommandSheet extends StatefulWidget {
  const KsVoiceCommandSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KsVoiceCommandSheet(),
    );
  }

  @override
  State<KsVoiceCommandSheet> createState() => _KsVoiceCommandSheetState();
}

enum _Command { accept, reject, repeat, back, retakePhoto, setPrice }

class _KsVoiceCommandSheetState extends State<KsVoiceCommandSheet> {
  _SheetState _state = _SheetState.idle;
  String? _heardText;

  Future<void> _listenOnce() async {
    final provider = context.read<SessionProvider>();
    final langCode = KsStrings.sarvamLangCode(context);
    setState(() => _state = _SheetState.recording);
    await provider.startRecording();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _state = _SheetState.processing);

    // Record raw audio through the provider's recorder for a fixed window,
    // then transcribe directly — this sheet must not touch the Live
    // cataloger session, only match commands.
    final wav = await provider.stopRecordingRaw();
    final (transcript, _) = wav != null
        ? await ApiService.transcribeAudio(wav, langCode)
        : ('', null);
    if (!mounted) return;
    _heardText = transcript;
    final command = _match(transcript);
    if (command == null) {
      setState(() => _state = _SheetState.unrecognised);
      return;
    }
    await _dispatch(command, transcript, provider, langCode);
  }

  _Command? _match(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    bool has(List<String> phrases) => phrases.any(t.contains);

    if (has(['daam', 'दाम'])) return _Command.setPrice;
    if (has(['photo dobara', 'फोटो दोबारा'])) return _Command.retakePhoto;
    if (has(['peeche', 'पीछे'])) return _Command.back;
    if (has(['phir se', 'फिर से'])) return _Command.repeat;
    if (has(['theek hai', 'ठीक है', 'haan', 'हाँ', 'हो'])) return _Command.accept;
    if (has(['galat', 'गलत', 'nahin', 'नहीं'])) return _Command.reject;
    return null;
  }

  Future<void> _dispatch(
    _Command cmd,
    String raw,
    SessionProvider provider,
    String langCode,
  ) async {
    switch (cmd) {
      case _Command.repeat:
        if (!mounted) return;
        Navigator.of(context).pop();
        final last = provider.lastSpokenText;
        if (last != null) await provider.speakText(last, langCode: langCode);
        return;
      case _Command.back:
        if (!mounted) return;
        Navigator.of(context).pop();
        if (context.canPop()) context.pop();
        return;
      case _Command.retakePhoto:
        if (!mounted) return;
        Navigator.of(context).pop();
        context.go(AppRoutes.capture);
        return;
      case _Command.setPrice:
        final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
        final price = digits != null ? int.tryParse(digits) : null;
        if (!mounted) return;
        Navigator.of(context).pop();
        if (price != null) provider.setListedPrice(price);
        return;
      case _Command.accept:
      case _Command.reject:
        // A generic header sheet has no direct handle on "the current
        // screen's confirm/reject" callback; it returns the result so the
        // caller (KsAppHeader / the screen) can act on it if it cares.
        if (!mounted) return;
        Navigator.of(context).pop(cmd == _Command.accept ? 'accept' : 'reject');
        return;
    }
  }

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KsColors.terracotta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mic_none_rounded, color: KsColors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice commands', style: KsTextStyles.h3),
                  Text('theek hai · galat · phir se · peeche · daam <number>',
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
          if (_state == _SheetState.unrecognised) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KsColors.peach3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Did not understand: "${_heardText ?? ''}"',
                      style: KsTextStyles.bodyMedium()),
                  const SizedBox(height: 4),
                  Text('Try one of the phrases above.', style: KsTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_state == _SheetState.processing) ...[
            const Center(child: CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2)),
            const SizedBox(height: 16),
          ],
          Center(
            child: GestureDetector(
              onTap: _state == _SheetState.recording || _state == _SheetState.processing
                  ? null
                  : _listenOnce,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _state == _SheetState.recording ? KsColors.terracotta : KsColors.surface1,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _state == _SheetState.recording ? KsColors.terracotta : KsColors.border,
                    width: _state == _SheetState.recording ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 32,
                  color: _state == _SheetState.recording ? KsColors.white : KsColors.terracotta,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _state == _SheetState.recording ? 'Listening…' : 'Tap and say a command',
            textAlign: TextAlign.center,
            style: KsTextStyles.body(color: KsColors.textSecondary, size: 12),
          ),
        ],
      ),
    );
  }
}
