import 'package:flutter/material.dart';
import '../../models/provenance.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// `00_AGENT_RULES.md`: "Never render `value` without a way to see
/// provenance... Provenance missing on a price? Bug. Do not ship that screen."
///
/// A null [provenance] renders the red variant deliberately — it is meant
/// to be a visible bug surface during development, not hidden.
class KsProvenanceChip extends StatelessWidget {
  const KsProvenanceChip({super.key, required this.provenance});

  final Provenance? provenance;

  @override
  Widget build(BuildContext context) {
    final p = provenance;
    final missing = p == null;
    return GestureDetector(
      onTap: () => _show(context, p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: missing ? const Color(0xFFFBE4E1) : KsColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: missing ? const Color(0xFFD9463A) : KsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              missing ? Icons.error_outline : Icons.verified_outlined,
              size: 11,
              color: missing ? const Color(0xFFD9463A) : KsColors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              missing ? 'no provenance' : 'AI · ${((p.confidence) * 100).round()}%',
              style: KsTextStyles.caption.copyWith(
                fontSize: 9,
                color: missing ? const Color(0xFFD9463A) : KsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context, Provenance? p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provenance', style: KsTextStyles.h3),
            const SizedBox(height: 12),
            if (p == null)
              Text('This value has no provenance attached — that is a bug, not a mock.',
                  style: KsTextStyles.body())
            else ...[
              _row('Source', p.source),
              if (p.version != null) _row('Version', p.version!),
              _row('Confidence', '${(p.confidence * 100).round()}%'),
              _row('Timestamp', p.ts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(k, style: KsTextStyles.caption)),
            Expanded(child: Text(v, style: KsTextStyles.bodyMedium())),
          ],
        ),
      );
}
