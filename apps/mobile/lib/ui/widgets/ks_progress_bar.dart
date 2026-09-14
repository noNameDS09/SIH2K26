import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsProgressBar extends StatelessWidget {
  const KsProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: KsTextStyles.label),
            const Spacer(),
            Text('$current of $total Completed', style: KsTextStyles.caption),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress,
            backgroundColor: KsColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation(KsColors.terracotta),
          ),
        ),
      ],
    );
  }
}
