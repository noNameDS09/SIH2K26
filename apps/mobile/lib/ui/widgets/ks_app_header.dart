import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const KsAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KsColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: KsColors.ink,
                    ),
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: KsTextStyles.section),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
