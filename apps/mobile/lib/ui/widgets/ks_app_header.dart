import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsAppHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
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
          ),
        Expanded(
          child: Text(
            title,
            style: KsTextStyles.section,
          ),
        ),
        if (showProfile)
          Material(
            color: KsColors.terracottaDark,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile opened')),
              ),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 19),
              ),
            ),
          ),
      ],
    );
  }
}
