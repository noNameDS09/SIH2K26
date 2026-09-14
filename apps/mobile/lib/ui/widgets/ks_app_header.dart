import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const KsAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showProfile = true,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showProfile;

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
                if (showProfile)
                  Material(
                    color: KsColors.terracottaDark,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile — Coming Soon'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
