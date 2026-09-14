import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class KsCard extends StatelessWidget {
  const KsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: KsColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KsColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class KsPill extends StatelessWidget {
  const KsPill({
    super.key,
    required this.text,
    this.icon,
    this.green = false,
  });

  final String text;
  final IconData? icon;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final bg = green ? KsColors.greenSoft : KsColors.terracottaSoft;
    final fg = green ? KsColors.greenDark : KsColors.terracottaDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: KsTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class KsActionButton extends StatelessWidget {
  const KsActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: secondary ? KsColors.white : KsColors.terracotta,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: secondary
                  ? Border.all(color: KsColors.border)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 17,
                    color: secondary ? KsColors.terracotta : KsColors.white,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: KsTextStyles.button.copyWith(
                    color: secondary ? KsColors.terracotta : KsColors.white,
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
