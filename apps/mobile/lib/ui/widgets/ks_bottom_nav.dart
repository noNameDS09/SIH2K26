import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsBottomNav extends StatelessWidget {
  const KsBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, 'Studio'),
    (Icons.grid_view_rounded, 'Kala List'),
    (Icons.mic_none_rounded, 'Bolo'),
    (Icons.groups_outlined, 'Samuh'),
    (Icons.storefront_outlined, 'Bazaar'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: KsColors.white,
          border: Border(top: BorderSide(color: KsColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: List.generate(_items.length, (index) {
            final selected = index == currentIndex;
            final item = _items[index];

            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.$2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? KsColors.terracotta
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$1,
                          size: 20,
                          color: selected
                              ? KsColors.white
                              : KsColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KsTextStyles.caption.copyWith(
                            fontSize: 8,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? KsColors.white
                                : KsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
