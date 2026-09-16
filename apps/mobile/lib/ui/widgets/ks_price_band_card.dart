import 'package:flutter/material.dart';
import '../../models/prices.dart';
import '../../models/provenance.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import 'ks_provenance_chip.dart';

/// Floor / recommended / aspirational bands, each with its own provenance
/// chip (`13_API.md`: "Provenance on each number"). [selectedKey] is one of
/// `floor`, `recommended`, `aspirational`, or `null` when a custom price is
/// active instead.
class KsPriceBandCard extends StatelessWidget {
  const KsPriceBandCard({
    super.key,
    required this.prices,
    required this.selectedKey,
    required this.onSelect,
  });

  final Prices prices;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bands = [
      ('floor', 'Floor', prices.floor),
      ('recommended', 'Recommended', prices.recommended),
      ('aspirational', 'Aspirational', prices.aspirational),
    ];
    return Row(
      children: [
        for (final (key, label, traced) in bands) ...[
          if (key != 'floor') const SizedBox(width: 8),
          Expanded(
            child: _Band(
              label: label,
              traced: traced,
              active: selectedKey == key,
              onTap: traced == null ? null : () => onSelect(key),
            ),
          ),
        ],
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.label, required this.traced, required this.active, this.onTap});

  final String label;
  final Traced<int>? traced;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = traced?.value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? KsColors.terracotta : KsColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? KsColors.terracotta : KsColors.peach3),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: KsTextStyles.label(
                    color: active ? KsColors.white.withAlpha(180) : KsColors.brown3, size: 8)),
            const SizedBox(height: 4),
            Text(
              value != null ? '₹$value' : '—',
              style: KsTextStyles.price(color: active ? KsColors.white : KsColors.mainText, size: 16),
            ),
            const SizedBox(height: 4),
            KsProvenanceChip(provenance: traced?.provenance),
          ],
        ),
      ),
    );
  }
}
