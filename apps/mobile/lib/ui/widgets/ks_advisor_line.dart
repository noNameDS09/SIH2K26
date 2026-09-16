import 'package:flutter/material.dart';
import '../../models/advisor_line.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import 'ks_provenance_chip.dart';

/// Agent B output. `10_VOICE_AND_AGENTS.md`: "If no rule fires, empty. Do
/// not fill with generic tips." — a null [line] renders **nothing**, not a
/// placeholder greeting. That silence is itself the spec'd behaviour.
class KsAdvisorLine extends StatelessWidget {
  const KsAdvisorLine({super.key, required this.line, this.onSpeak});

  final AdvisorLine? line;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final l = line;
    if (l == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KsColors.peach3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onSpeak != null)
            InkWell(
              onTap: onSpeak,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.volume_up_outlined, size: 18, color: KsColors.terracotta),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(child: Text(l.text, style: KsTextStyles.body(size: 13))),
          const SizedBox(width: 8),
          KsProvenanceChip(provenance: l.provenance),
        ],
      ),
    );
  }
}
