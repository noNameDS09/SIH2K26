import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_stage_progress.dart';
import '../widgets/ks_mock_badge.dart';
import '../widgets/ks_provenance_chip.dart';
import '../../models/provenance.dart';

/// Stage 2 — original vs. studio compare, six bundled backgrounds, ΔE
/// quality gate. `09_IMAGE_PIPELINE.md` calls this "the quality bottleneck"
/// of the whole build: a rejected gate must never publish a bad mask, and
/// only the six named presets exist — no generated/downloaded backgrounds.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

/// (presetKey, label, swatch) — presetKey is sent verbatim as `bg_preset`
/// to `POST /v1/images/enhance`; it must match the server's six-preset enum.
const _presets = [
  ('white', 'White', Color(0xFFFAFAF8)),
  ('linen', 'Linen', Color(0xFFEFE6D8)),
  ('beige', 'Beige', Color(0xFFE3D2B8)),
  ('slate', 'Slate', Color(0xFF5B6670)),
  ('jute', 'Jute', Color(0xFFB89968)),
  ('wood', 'Wood', Color(0xFF7C4A2D)),
];

class _StudioScreenState extends State<StudioScreen> {
  String _selectedPreset = 'linen';
  bool _showEnhanced = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final original = provider.capturedImageBytes;
        final enhanced = provider.enhancedImageBytes;
        final rejected = provider.enhanceRejected;
        final offline = provider.enhanceOffline;
        // A rejected/offline result must never be shown as "the studio
        // photo" — force the original into view in that case.
        final canShowEnhanced = enhanced != null && !rejected && !offline;
        final showEnhanced = _showEnhanced && canShowEnhanced;

        return Scaffold(
          backgroundColor: KsColors.background,
          body: Column(
            children: [
              KsAppHeader(
                title: 'Studio',
                onBack: () => context.go(AppRoutes.capture),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const KsStageProgress(stage: 2, label: 'PHOTO STUDIO'),
                      const SizedBox(height: 20),

                      if (original != null) ...[
                        _ImagePreviewCard(
                          original: original,
                          enhanced: enhanced,
                          showEnhanced: showEnhanced,
                          canShowEnhanced: canShowEnhanced,
                          onToggle: canShowEnhanced
                              ? () => setState(() => _showEnhanced = !_showEnhanced)
                              : null,
                          deltaE: provider.imageEnhanceDeltaE,
                          provenance: provider.enhanceProvenance,
                        ),
                        const SizedBox(height: 12),
                        if (rejected) ...[
                          _StatusBanner(
                            icon: Icons.report_gmailerrorred_rounded,
                            color: const Color(0xFFD9463A),
                            text:
                                'Studio image rejected — colour shifted too far (ΔE ${provider.imageEnhanceDeltaE?.toStringAsFixed(1) ?? '?'} > 2.0). Showing the original photo instead.',
                          ),
                          const SizedBox(height: 12),
                        ] else if (offline) ...[
                          const _StatusBanner(
                            icon: Icons.wifi_off_rounded,
                            color: KsColors.textSecondary,
                            text: 'Waiting for network — showing the original photo until the studio server responds.',
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                      ] else ...[
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: KsColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined, size: 48, color: KsColors.textSecondary),
                                SizedBox(height: 8),
                                Text('No photo captured',
                                    style: TextStyle(color: KsColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Row(
                        children: [
                          Text('Background Preset',
                              style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                          const Spacer(),
                          const KsMockBadge(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _presets.length,
                        itemBuilder: (context, i) {
                          final (key, label, swatch) = _presets[i];
                          final selected = _selectedPreset == key;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedPreset = key);
                              if (original != null) {
                                provider.reEnhanceWithPreset(preset: key);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: swatch,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? KsColors.terracotta : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [BoxShadow(color: KsColors.terracotta.withAlpha(77), blurRadius: 8)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: swatch.computeLuminance() > 0.5
                                        ? KsColors.mainText
                                        : KsColors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      if (provider.isEnhancing) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: KsColors.surface1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  color: KsColors.terracotta, strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Enhancing with AI…',
                                  style: KsTextStyles.body(size: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(AppRoutes.live),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Continue to Voice Q&A'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KsColors.terracotta,
                            foregroundColor: KsColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: KsTextStyles.body(size: 12, color: color))),
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  final Uint8List original;
  final Uint8List? enhanced;
  final bool showEnhanced;
  final bool canShowEnhanced;
  final VoidCallback? onToggle;
  final double? deltaE;
  final Provenance? provenance;

  const _ImagePreviewCard({
    required this.original,
    this.enhanced,
    required this.showEnhanced,
    required this.canShowEnhanced,
    this.onToggle,
    this.deltaE,
    this.provenance,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = showEnhanced && enhanced != null ? enhanced! : original;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            imageBytes,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (canShowEnhanced) ...[
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: showEnhanced ? KsColors.terracotta : KsColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    showEnhanced ? 'Studio ✦' : 'Original',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: showEnhanced ? KsColors.white : KsColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KsColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Original',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KsColors.textSecondary)),
              ),
            if (deltaE != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: deltaE! > 2.0 ? const Color(0xFFFBE4E1) : KsColors.paleGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ΔE ${deltaE!.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: deltaE! > 2.0 ? const Color(0xFFD9463A) : KsColors.deepGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            KsProvenanceChip(provenance: provenance),
          ],
        ),
      ],
    );
  }
}
