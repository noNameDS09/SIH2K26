import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../routes/app_routes.dart';
import 'ks_voice_command_sheet.dart';

class KsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const KsAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showProfile = true,
    this.showSahayak = false,
    this.languageChip,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showProfile;
  final bool showSahayak;
  final String? languageChip;

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

                // Language chip
                if (languageChip != null) ...[
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.language),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: KsColors.peach3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(languageChip!,
                          style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Sahayak mic button
                if (showSahayak) ...[
                  IconButton(
                    tooltip: 'Voice commands',
                    onPressed: () => KsVoiceCommandSheet.show(context),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      foregroundColor: KsColors.terracotta,
                      backgroundColor: KsColors.peach3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                if (showProfile)
                  Material(
                    color: KsColors.terracottaDark,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.go(AppRoutes.settings),
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
