import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showAudio;

  const KsAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showAudio = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64 + top,
          color: KsColors.background.withAlpha(230),
          padding: EdgeInsets.only(top: top, left: 16, right: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.arrow_back, color: KsColors.mainText, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: KsTextStyles.appBarTitle())),
              if (showAudio) ...[
                const Icon(Icons.volume_up_outlined, color: KsColors.mainText, size: 22),
                const SizedBox(width: 12),
              ],
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: KsColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: KsColors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
