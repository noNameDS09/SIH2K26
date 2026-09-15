import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsProgressBar extends StatelessWidget {
  const KsProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.label,
  });

  final int totalSteps;
  final int currentStep;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (label != null)
              Text(label!, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
            const Spacer(),
            Text('$currentStep of $totalSteps Steps',
                style: KsTextStyles.caption),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            totalSteps,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < currentStep
                      ? KsColors.terracotta
                      : KsColors.surfaceMuted,
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
