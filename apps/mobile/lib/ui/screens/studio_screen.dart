import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  int _selectedPreset = 0;
  bool _showEnhanced = true;

  static const _presets = [
    ('Natural Light', Icons.wb_sunny_outlined, Color(0xFFF5E6D3)),
    ('Neutral White', Icons.radio_button_unchecked, Color(0xFFF8F8F8)),
    ('Studio Grey', Icons.panorama_rounded, Color(0xFFE8E8E8)),
    ('Deep Forest', Icons.forest_outlined, Color(0xFF2D5A27)),
    ('Indigo Silk', Icons.water_rounded, Color(0xFF3B3B8C)),
    ('Terracotta', Icons.circle, Color(0xFFB8541E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final original = provider.capturedImageBytes;
        final enhanced = provider.enhancedImageBytes;
        final showEnhanced = _showEnhanced && enhanced != null;

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
                      const KsProgressBar(
                        totalSteps: 7,
                        currentStep: 3,
                        label: 'STAGE 3 — PHOTO STUDIO',
                      ),
                      const SizedBox(height: 20),

                      // Image preview with before/after toggle
                      if (original != null) ...[
                        _ImagePreviewCard(
                          original: original,
                          enhanced: enhanced,
                          showEnhanced: showEnhanced,
                          onToggle: () => setState(() => _showEnhanced = !_showEnhanced),
                          deltaE: provider.imageEnhanceDeltaE,
                        ),
                        const SizedBox(height: 20),
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

                      // Background presets
                      Text('Background Preset',
                          style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
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
                          final preset = _presets[i];
                          final selected = _selectedPreset == i;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedPreset = i);
                              if (original != null) {
                                provider.reEnhanceWithPreset(
                                  preset: preset.$1.toLowerCase().replaceAll(' ', '_'),
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: preset.$3,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? KsColors.terracotta : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [BoxShadow(color: KsColors.terracotta.withAlpha(77), blurRadius: 8)]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(preset.$2, size: 20,
                                      color: preset.$3.computeLuminance() > 0.5
                                          ? KsColors.mainText
                                          : KsColors.white),
                                  const SizedBox(height: 4),
                                  Text(
                                    preset.$1,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: preset.$3.computeLuminance() > 0.5
                                          ? KsColors.mainText
                                          : KsColors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Loading indicator for enhancement
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

                      // Continue CTA
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

class _ImagePreviewCard extends StatelessWidget {
  final Uint8List original;
  final Uint8List? enhanced;
  final bool showEnhanced;
  final VoidCallback onToggle;
  final double? deltaE;

  const _ImagePreviewCard({
    required this.original,
    this.enhanced,
    required this.showEnhanced,
    required this.onToggle,
    this.deltaE,
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
            if (enhanced != null) ...[
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: showEnhanced ? KsColors.terracotta : KsColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    showEnhanced ? 'Enhanced ✦' : 'Original',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: showEnhanced ? KsColors.white : KsColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (deltaE != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: KsColors.paleGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ΔE ${deltaE!.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: KsColors.deepGreen),
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }
}
