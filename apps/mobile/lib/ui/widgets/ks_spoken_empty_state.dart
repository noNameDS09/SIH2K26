import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// Honest empty state that speaks once on first build — spec pattern for
/// money/shop/insights when there is genuinely nothing yet ("no sales
/// yet" rather than silence or a fake placeholder number).
class KsSpokenEmptyState extends StatefulWidget {
  const KsSpokenEmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.langCode = 'hi-IN',
  });

  final IconData icon;
  final String text;
  final String langCode;

  @override
  State<KsSpokenEmptyState> createState() => _KsSpokenEmptyStateState();
}

class _KsSpokenEmptyStateState extends State<KsSpokenEmptyState> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SessionProvider>().speakText(widget.text, langCode: widget.langCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(widget.icon, size: 40, color: KsColors.textSecondary),
          const SizedBox(height: 12),
          Text(widget.text, textAlign: TextAlign.center,
              style: KsTextStyles.body(color: KsColors.textSecondary, size: 13)),
        ],
      ),
    );
  }
}
