import 'package:flutter/material.dart';
import '../../models/trend.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import 'ks_provenance_chip.dart';

/// Trend line from `public_trends/current` (Agent C). Spec requirement:
/// always show `n` alongside the number, and label it seeded when
/// `n < 20` — "do not present a seeded number as observed"
/// (`10_VOICE_AND_AGENTS.md`).
class KsTrendLineCard extends StatelessWidget {
  const KsTrendLineCard({super.key, required this.trend});

  final Trend? trend;

  @override
  Widget build(BuildContext context) {
    final t = trend;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KsColors.peach3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('CLUSTER TREND', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
            const Spacer(),
            KsProvenanceChip(provenance: t?.provenance),
          ]),
          const SizedBox(height: 10),
          if (t == null) ...[
            Text('No trend data yet for this cluster.', style: KsTextStyles.body(size: 12)),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (t.series.length >= 2) ...[
                  SizedBox(
                    width: 72,
                    height: 32,
                    child: CustomPaint(painter: _SparklinePainter(t.series)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.craft ?? 'This craft', style: KsTextStyles.bodyMedium(size: 13)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text('n=${t.n}', style: KsTextStyles.caption),
                        if (t.seed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KsColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('seed',
                                style: KsTextStyles.caption.copyWith(fontSize: 9)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            if (t.rising.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: t.rising
                    .map((r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: KsColors.paleGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('↑ $r',
                              style: KsTextStyles.caption.copyWith(color: KsColors.deepGreen)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = KsColors.terracotta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}
