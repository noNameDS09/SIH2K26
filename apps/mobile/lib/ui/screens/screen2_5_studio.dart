import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class ScreenStudio extends StatefulWidget {
  const ScreenStudio({super.key});
  @override State<ScreenStudio> createState() => _ScreenStudioState();
}

class _ScreenStudioState extends State<ScreenStudio> with SingleTickerProviderStateMixin {
  String? _selectedPreset;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final originalBytes = session.capturedImageBytes;
    final enhancedBytes = session.enhancedImageBytes;
    final isEnhancing = session.isEnhancing;
    final isMock = session.enhancedIsMock;
    final deltaE = session.listingId != null ? 'passed' : '—';

    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: AppBar(
        title: Text('Image Studio', style: KsTextStyles.section),
        backgroundColor: KsColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original vs Enhanced', style: KsTextStyles.section),
            const SizedBox(height: 4),
            Text('Select a background surface. Light adjustments preserve colour.', style: KsTextStyles.body()),
            const SizedBox(height: 16),
            if (isEnhancing)
              Center(child: CircularProgressIndicator(color: KsColors.terracotta)),
            if (!isEnhancing && originalBytes != null)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: KsColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KsColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: originalBytes != null
                          ? Image.memory(originalBytes, fit: BoxFit.contain)
                          : const Center(child: Text('No original')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: enhancedBytes != null ? KsColors.surfaceWarm : KsColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: enhancedBytes != null ? KsColors.greenSoft : KsColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: enhancedBytes != null
                          ? Image.memory(enhancedBytes, fit: BoxFit.contain)
                          : const Center(child: Text('Not enhanced yet')),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                'white', 'linen', 'beige', 'slate', 'jute', 'wood',
              ].map((preset) {
                final selected = _selectedPreset == preset;
                return ChoiceChip(
                  label: Text(preset),
                  selected: selected,
                  onSelected: (val) => setState(() => _selectedPreset = val ? preset : null),
                  selectedColor: KsColors.terracotta.withOpacity(0.15),
                  labelStyle: TextStyle(color: selected ? KsColors.terracotta : KsColors.ink),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ΔE: $deltaE  |  Preset: ${_selectedPreset ?? 'auto'}',
                    style: KsTextStyles.body(color: KsColors.textSecondary)),
                if (isMock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: KsColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Review required — enhanced unavailable',
                        style: KsTextStyles.body(size: 11, color: KsColors.orange)),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/live'),
                child: const Text('Continue to Catalog'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
