import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// `00_AGENT_RULES.md`: "Label mocks on screen: `Mock — for SIH demo`
/// (Aadhaar, live GeM/ONDC/IH)." One shared widget instead of ad-hoc chips
/// per screen so the label text never drifts.
class KsMockBadge extends StatelessWidget {
  const KsMockBadge({super.key});

  static const text = 'Mock — for SIH demo';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KsColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 11, color: KsColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: KsTextStyles.caption.copyWith(fontSize: 9, color: KsColors.textSecondary)),
        ],
      ),
    );
  }
}
