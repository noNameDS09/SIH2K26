import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// Single 6-stage progress bar per `04_FEATURES_AND_SCREENS.md`, replacing
/// the app's previous mixed 5-step/7-step scales.
///
/// Stage 1 Entry (language/otp/onboarding) · 2 Media (capture/studio) ·
/// 3 Money (live/intelligence/costing/pricing) · 4 Trust (approval) ·
/// 5 Out (distribute) · 6 Loop (home/shop/money/insights).
class KsStageProgress extends StatelessWidget {
  const KsStageProgress({super.key, required this.stage, this.label});

  static const totalStages = 6;

  final int stage; // 1..6
  final String? label;

  @override
  Widget build(BuildContext context) {
    final current = stage.clamp(1, totalStages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (label != null)
              Text(label!, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
            const Spacer(),
            Text('Stage $current of $totalStages', style: KsTextStyles.caption),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            totalStages,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == totalStages - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < current ? KsColors.terracotta : KsColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
