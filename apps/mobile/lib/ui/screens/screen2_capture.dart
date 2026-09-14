import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';
import '../l10n/ks_strings.dart';

class Screen2Capture extends StatefulWidget {
  const Screen2Capture({super.key});

  @override
  State<Screen2Capture> createState() => _Screen2CaptureState();
}

class _Screen2CaptureState extends State<Screen2Capture> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().init();
    });
  }

  Future<void> _openCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      final provider = context.read<SessionProvider>();
      final ks = KsStrings.of(context);
      await provider.setCapturedImage(bytes);
      if (mounted) _showSnack(ks.photoTaken);
    } catch (_) {
      if (mounted) _showSnack(KsStrings.of(context).cameraUnavailable);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      final provider = context.read<SessionProvider>();
      final ks = KsStrings.of(context);
      await provider.setCapturedImage(bytes);
      if (mounted) _showSnack(ks.photoSelected);
    } catch (_) {
      if (mounted) _showSnack(KsStrings.of(context).cameraUnavailable);
    }
  }

  void _loadSample() {
    final provider = context.read<SessionProvider>();
    final bytes = provider.capturedImageBytes;
    if (bytes == null) {
      _showSnack(KsStrings.of(context).sampleLoaded);
      return;
    }
    provider.setCapturedImage(bytes);
    _showSnack('Requesting new enhancement…');
  }

  Future<void> _toggleMic() async {
    final provider = context.read<SessionProvider>();
    if (provider.isRecording) {
      await provider.stopRecordingAndSubmit(langCode: 'mr-IN');
    } else {
      await provider.startRecording();
    }
  }

  Future<void> _playQuestion() async {
    final provider = context.read<SessionProvider>();
    final question = provider.currentQuestion;
    if (question != null) {
      await provider.speakText(question, langCode: 'mr-IN');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: KsTextStyles.body(color: KsColors.white, size: 13)),
        backgroundColor: KsColors.terracotta,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ks = KsStrings.of(context);
    return Consumer<SessionProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: KsColors.background,
        appBar: KsAppHeader(title: ks.productCapture),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _StageHeader(stage: '02', total: '05'),
              const SizedBox(height: 10),
              const KsProgressBar(totalSteps: 5, currentStep: 2),
              const SizedBox(height: 12),
              _StageBadge(label: ks.stage2Badge),
              const SizedBox(height: 20),
              _Heading(prefix: ks.greetingPrefix, craft: ks.craftName),
              const SizedBox(height: 8),
              Text(ks.captureHint, style: KsTextStyles.body()),
              const SizedBox(height: 20),
              // Show dual view when enhancement is ready, single view otherwise
              if (provider.capturedImageBytes != null &&
                  provider.enhancedImageBytes != null)
                _DualImageView(
                  originalBytes: provider.capturedImageBytes!,
                  enhancedBytes: provider.enhancedImageBytes!,
                  retakeLabel: ks.retake,
                  onRetake: _openCamera,
                )
              else
                _CameraViewport(
                  imageBytes: provider.capturedImageBytes,
                  isEnhancing: provider.isEnhancing,
                  tapLabel: ks.tapToCapture,
                  retakeLabel: ks.retake,
                  onTap: _openCamera,
                ),
              const SizedBox(height: 12),
              _ActionButtons(
                uploadLabel: ks.uploadPhoto,
                sampleLabel: ks.sample,
                onUpload: _pickFromGallery,
                onSample: _loadSample,
              ),
              const SizedBox(height: 24),
              _VoiceQueryCard(
                isListening: provider.isRecording,
                isLoading: provider.isLoading,
                statusMessage: provider.statusMessage,
                question: provider.currentQuestion ?? ks.voiceQuery,
                transcript: provider.lastTranscript,
                isDone: provider.isDone,
                onMicTap: _toggleMic,
                onPlayTap: _playQuestion,
                asrLabel: ks.voiceAsrLabel,
                languageName: ks.languageName,
                activeQueryLabel: ks.activeQuery,
                hintText: ks.missingInfoHint,
                listeningLabel: ks.listening,
              ),
              const SizedBox(height: 24),
              _RunIntelligenceButton(
                label: ks.runIntelligence,
                onTap: () => context.go('/intelligence'),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(ks.stepFooter,
                    style: KsTextStyles.label(color: KsColors.brown3, size: 11)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stage header ─────────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final String stage;
  final String total;
  const _StageHeader({required this.stage, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('STAGE $stage / $total',
            style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
        const Spacer(),
        Text('KALASETU AI PIPELINE',
            style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  const _StageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: KsTextStyles.label(color: KsColors.mainText, size: 11)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String prefix;
  final String craft;
  const _Heading({required this.prefix, required this.craft});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: '$prefix\n', style: KsTextStyles.editorial()),
        TextSpan(text: craft, style: KsTextStyles.editorialItalic()),
      ]),
    );
  }
}

// ─── Camera viewport ──────────────────────────────────────────────────────────

class _CameraViewport extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isEnhancing;
  final String tapLabel;
  final String retakeLabel;
  final VoidCallback onTap;
  const _CameraViewport({
    this.imageBytes,
    required this.isEnhancing,
    required this.tapLabel,
    required this.retakeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 262,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageBytes != null)
                Positioned.fill(
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (ctx2, err, st) => Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.white54, size: 40),
                      ),
                    ),
                  ),
                )
              else ...[
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3D2B1F), Color(0xFF5C3D2A), Color(0xFF2A1A12), Color(0xFF1A0F08)],
                      stops: [0, 0.35, 0.7, 1],
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _EarthyTexturePainter())),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: Colors.white.withAlpha(50), size: 48),
                      const SizedBox(height: 8),
                      Text(tapLabel,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withAlpha(120), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
              Positioned(
                bottom: 0, left: 0, right: 0, height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(165)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12, left: 12, right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HudChip(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('ISNet Active', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500)),
                    ])),
                    if (isEnhancing)
                      _HudChip(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(width: 8, height: 8,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)),
                        const SizedBox(width: 5),
                        const Text('Enhancing…', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500)),
                      ]))
                    else
                      _HudChip(child: const Text('Mask: 99.4%',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HudChip(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('QA: None (0.4s)', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500)),
                    ])),
                    if (imageBytes != null)
                      _HudChip(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.refresh, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(retakeLabel, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600)),
                      ]))
                    else
                      _HudChip(child: const Text('4K 60FPS',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final Widget child;
  const _HudChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.black.withAlpha(115), borderRadius: BorderRadius.circular(20)),
          child: child,
        ),
      ),
    );
  }
}

class _EarthyTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(6);
    for (var i = 0; i < size.width; i += 8) {
      for (var j = 0; j < size.height; j += 8) {
        if ((i + j) % 16 == 0) canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Upload / Sample buttons ──────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final String uploadLabel;
  final String sampleLabel;
  final VoidCallback onUpload;
  final VoidCallback onSample;
  const _ActionButtons({required this.uploadLabel, required this.sampleLabel, required this.onUpload, required this.onSample});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PillButton(label: uploadLabel, icon: Icons.upload_outlined, bg: KsColors.mainText, fg: KsColors.white, onTap: onUpload)),
        const SizedBox(width: 8),
        Expanded(child: _PillButton(label: sampleLabel, icon: Icons.refresh, bg: KsColors.peach3, fg: KsColors.darkBrown, onTap: onSample)),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: fg, size: 18), const SizedBox(width: 8), Text(label, style: KsTextStyles.cta(color: fg))],
        ),
      ),
    );
  }
}

// ─── Voice query card ─────────────────────────────────────────────────────────

class _VoiceQueryCard extends StatefulWidget {
  final bool isListening;
  final bool isLoading;
  final String? statusMessage;
  final String question;
  final String? transcript;
  final bool isDone;
  final Future<void> Function() onMicTap;
  final Future<void> Function() onPlayTap;
  final String asrLabel;
  final String languageName;
  final String activeQueryLabel;
  final String hintText;
  final String listeningLabel;

  const _VoiceQueryCard({
    required this.isListening,
    required this.isLoading,
    this.statusMessage,
    required this.question,
    this.transcript,
    required this.isDone,
    required this.onMicTap,
    required this.onPlayTap,
    required this.asrLabel,
    required this.languageName,
    required this.activeQueryLabel,
    required this.hintText,
    required this.listeningLabel,
  });

  @override
  State<_VoiceQueryCard> createState() => _VoiceQueryCardState();
}

class _VoiceQueryCardState extends State<_VoiceQueryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(_VoiceQueryCard old) {
    super.didUpdateWidget(old);
    if (widget.isListening != old.isListening) {
      if (widget.isListening) {
        _ripple.repeat(reverse: true);
      } else {
        _ripple.stop();
        _ripple.reset();
      }
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: KsColors.surface1, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 6),
              Text(widget.asrLabel, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.translate, size: 13, color: KsColors.brown3),
                  const SizedBox(height: 2),
                  Text(widget.languageName, textAlign: TextAlign.right,
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mic / loading indicator
          if (widget.isLoading)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2.5),
                  const SizedBox(height: 12),
                  Text(widget.statusMessage ?? 'Processing…',
                      style: KsTextStyles.label(color: KsColors.terracotta, size: 11)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: widget.onMicTap,
              child: Center(
                child: AnimatedBuilder(
                  animation: _ripple,
                  builder: (context2, snapshot) {
                    final scale = 1.0 + (_ripple.value * 0.18);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              color: KsColors.peach3.withAlpha(widget.isListening ? 90 : 60),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 1.0 + (_ripple.value * 0.12),
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: KsColors.peach2.withAlpha(widget.isListening ? 130 : 100),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Container(width: 74, height: 74,
                            decoration: BoxDecoration(color: KsColors.peach1.withAlpha(150), shape: BoxShape.circle)),
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: widget.isListening ? KsColors.orange : KsColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.isListening ? Icons.stop : Icons.mic, color: KsColors.white, size: 26),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          if (widget.isListening) ...[
            const SizedBox(height: 10),
            Center(child: Text(widget.listeningLabel, style: KsTextStyles.label(color: KsColors.terracotta, size: 11))),
          ],
          if (widget.isDone) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: KsColors.paleGreen, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: KsColors.deepGreen, size: 16),
                const SizedBox(width: 8),
                Text('सर्व माहिती नोंदवली आहे!', style: KsTextStyles.label(color: KsColors.deepGreen, size: 11)),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KsColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: KsColors.darkBrown.withAlpha(12), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: KsColors.terracotta, size: 14),
                    const SizedBox(width: 5),
                    Text(widget.activeQueryLabel, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onPlayTap,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: KsColors.surface2, shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up_outlined, color: KsColors.terracotta, size: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.question,
                  style: GoogleFonts.plusJakartaSans(
                    color: KsColors.mainText, fontSize: 14, height: 1.55, fontWeight: FontWeight.w500),
                ),
                if (widget.transcript != null && widget.transcript!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: KsColors.peach3, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: KsColors.terracotta, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(widget.transcript!,
                              style: KsTextStyles.body(color: KsColors.mainText, size: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 4, height: 4,
                          decoration: const BoxDecoration(color: KsColors.brown3, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(widget.hintText, style: KsTextStyles.body(color: KsColors.brown3, size: 11))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dual image view (original + enhanced) ────────────────────────────────────

class _DualImageView extends StatelessWidget {
  final Uint8List originalBytes;
  final Uint8List enhancedBytes;
  final String retakeLabel;
  final VoidCallback onRetake;

  const _DualImageView({
    required this.originalBytes,
    required this.enhancedBytes,
    required this.retakeLabel,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ImagePanel(
                label: 'Original',
                bytes: originalBytes,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ImagePanel(
                label: 'Enhanced',
                bytes: enhancedBytes,
                isEnhanced: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onRetake,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: KsColors.mainText,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh, color: KsColors.white, size: 12),
                const SizedBox(width: 4),
                Text(retakeLabel,
                    style: KsTextStyles.label(
                        color: KsColors.white, size: 10)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePanel extends StatelessWidget {
  final String label;
  final Uint8List bytes;
  final bool isEnhanced;

  const _ImagePanel({
    required this.label,
    required this.bytes,
    this.isEnhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnhanced
                      ? KsColors.terracotta
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: KsTextStyles.label(
                        color: KsColors.white, size: 9)),
              ),
            ),
            if (isEnhanced)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Color(0xFF4ADE80),
                  child: Icon(Icons.auto_awesome,
                      size: 11, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Run Intelligence CTA ─────────────────────────────────────────────────────

class _RunIntelligenceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RunIntelligenceButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: KsColors.terracotta,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: KsColors.terracotta.withAlpha(70), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: KsColors.white, size: 18),
            const SizedBox(width: 10),
            Text(label, style: KsTextStyles.cta(size: 15)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, color: KsColors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
