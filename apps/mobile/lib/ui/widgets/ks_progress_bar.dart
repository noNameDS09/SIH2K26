import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

class KsProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const KsProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i < currentStep;
        return Expanded(
          child: Container(
            margin: i < totalSteps - 1 ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
            height: 4,
            decoration: BoxDecoration(
              color: active ? KsColors.terracotta : KsColors.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
