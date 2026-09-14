import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
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
              // Back button — uses GoRouter when possible
              GestureDetector(
                onTap: onBack ??
                    () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      }
                    },
                child: const Icon(Icons.arrow_back,
                    color: KsColors.mainText, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: KsTextStyles.appBarTitle())),
              // Audio icon — speaks the screen title via TTS
              if (showAudio) ...[
                GestureDetector(
                  onTap: () {
                    try {
                      context.read<SessionProvider>().speakText(title);
                    } catch (_) {}
                  },
                  child: const Icon(Icons.volume_up_outlined,
                      color: KsColors.mainText, size: 22),
                ),
                const SizedBox(width: 12),
              ],
              // Profile button — shows bottom sheet
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const _ProfileSheet(),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: KsColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.person, color: KsColors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile bottom sheet ─────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: KsColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KsColors.peach3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: KsColors.peach3,
              child: Icon(Icons.person_outline,
                  size: 44, color: KsColors.terracotta),
            ),
            const SizedBox(height: 16),
            Text('Artisan Profile', style: KsTextStyles.editorial(size: 20)),
            const SizedBox(height: 8),
            Text(
              'No profile set up yet.\nComplete onboarding to create your\ndigital artisan identity on ONDC & GeM.',
              textAlign: TextAlign.center,
              style: KsTextStyles.body(color: KsColors.brown3),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: KsColors.terracotta,
                  shape: const StadiumBorder(),
                ),
                child: Text('Close',
                    style: KsTextStyles.cta(color: KsColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
