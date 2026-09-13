import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const KsBottomNav({super.key, this.currentIndex = 0, this.onTap});

  static const _labels = ['Studio', 'Kala List', 'Bolo', 'Samuh', 'Bazaar'];
  static const _icons = [
    Icons.photo_filter_outlined,
    Icons.list_alt_outlined,
    Icons.mic,
    Icons.people_outline,
    Icons.storefront_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: KsColors.background.withAlpha(230),
            boxShadow: [
              BoxShadow(
                color: KsColors.darkBrown.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (i) {
              final isBolo = i == 2;
              final isActive = i == currentIndex;
              final color = isActive ? KsColors.terracotta : KsColors.brown3;

              if (isBolo) {
                return GestureDetector(
                  onTap: () => onTap?.call(i),
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: KsColors.terracotta,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: KsColors.terracotta.withAlpha(80),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic, color: KsColors.white, size: 22),
                          Text('Bolo',
                              style: KsTextStyles.label(color: KsColors.white, size: 9)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onTap?.call(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icons[i], color: color, size: 22),
                    const SizedBox(height: 2),
                    Text(_labels[i], style: KsTextStyles.label(color: color, size: 10)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
