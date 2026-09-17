import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String _preset = "linen";
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final hasEnhanced = provider.enhancedImageBytes != null;
    final imageToShow = _showOriginal
        ? provider.capturedImageBytes
        : (provider.enhancedImageBytes ?? provider.capturedImageBytes);

    return Scaffold(
      backgroundColor: KsColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KsAppHeader(
                title: 'Studio Enhancement',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 12),
              const KsProgressBar(
                totalSteps: 7,
                currentStep: 2,
                label: 'STAGE 2 — STUDIO ENHANCEMENT',
              ),
              const SizedBox(height: 16),
              Text("Preset: $_preset",
                  style: const TextStyle(
                      fontSize: 11, color: KsColors.textSecondary)),
              const SizedBox(height: 12),

              // Image display
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: KsColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: provider.isEnhancing
                      ? const SizedBox(
                          height: 260,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                    color: KsColors.terracotta),
                                SizedBox(height: 16),
                                Text('Enhancing your product image…',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: KsColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : imageToShow != null
                          ? Image.memory(imageToShow,
                              fit: BoxFit.contain, width: double.infinity)
                          : const SizedBox(
                              height: 260,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_rounded,
                                        size: 48, color: KsColors.textMuted),
                                    SizedBox(height: 12),
                                    Text("No image available"),
                                  ],
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 14),

              // Preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ["linen", "white", "slate", "jute", "wood", "beige"]
                    .map((preset) => ChoiceChip(
                          label: Text(preset),
                          selected: _preset == preset,
                          selectedColor: KsColors.terracotta,
                          labelStyle: TextStyle(
                              color: _preset == preset
                                  ? Colors.white
                                  : KsColors.ink),
                          onSelected: (selected) =>
                              setState(() => _preset = preset),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Toggle original/enhanced
              if (hasEnhanced)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showOriginal = !_showOriginal),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KsColors.terracotta,
                      side: const BorderSide(color: KsColors.terracotta),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_showOriginal
                        ? Icons.auto_fix_high_rounded
                        : Icons.image_outlined),
                    label: Text(
                        _showOriginal ? "Show Enhanced" : "Show Original"),
                  ),
                ),
              const SizedBox(height: 12),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: provider.isEnhancing
                      ? null
                      : () => context.push("/live"),
                  style: FilledButton.styleFrom(
                    backgroundColor: KsColors.terracotta,
                    disabledBackgroundColor: KsColors.surfaceMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Continue to Cataloger"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
