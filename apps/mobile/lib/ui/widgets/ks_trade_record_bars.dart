import 'package:flutter/material.dart';
import '../../models/artisan.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// Five bars: identity, listings, sales, consistency, cluster. Unlocks
/// only — never a penalty, never labelled "credit score"
/// (`00_AGENT_RULES.md`).
class KsTradeRecordBars extends StatelessWidget {
  const KsTradeRecordBars({super.key, required this.record});

  final TradeRecord record;

  static const _labels = ['Identity', 'Listings', 'Sales', 'Consistency', 'Cluster'];

  @override
  Widget build(BuildContext context) {
    final bars = record.bars;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trade Record', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
          const SizedBox(height: 12),
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 80, child: Text(_labels[i], style: KsTextStyles.caption)),
                Expanded(
                  child: Row(
                    children: List.generate(5, (bar) => Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: bar == 4 ? 0 : 4),
                            decoration: BoxDecoration(
                              color: bar < bars[i] ? KsColors.terracotta : KsColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text('Bars unlock features as your trade history grows — they never lock anything away.',
              style: KsTextStyles.caption.copyWith(color: KsColors.textSecondary)),
        ],
      ),
    );
  }
}
