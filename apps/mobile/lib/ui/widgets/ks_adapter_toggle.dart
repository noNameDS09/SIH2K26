import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import 'ks_mock_badge.dart';

/// One GeM / ONDC / IndiaHandmade row. `00_AGENT_RULES.md`: "Do not claim
/// live GeM/ONDC/IndiaHandmade writes" — this always carries the standard
/// mock badge and, on toggle, shows the *shaped JSON* the server would send
/// rather than claiming anything actually went live.
class KsAdapterToggle extends StatefulWidget {
  const KsAdapterToggle({
    super.key,
    required this.channel,
    required this.label,
    required this.listingId,
  });

  final String channel;
  final String label;
  final String? listingId;

  @override
  State<KsAdapterToggle> createState() => _KsAdapterToggleState();
}

class _KsAdapterToggleState extends State<KsAdapterToggle> {
  bool _enabled = false;
  bool _loading = false;
  Map<String, dynamic>? _shaped;

  Future<void> _toggle(bool value) async {
    setState(() { _enabled = value; _loading = value; });
    if (!value || widget.listingId == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await ApiService.exportListing(widget.listingId!, widget.channel);
    if (!mounted) return;
    setState(() { _loading = false; _shaped = result; });
  }

  void _viewJson() {
    if (_shaped == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('${widget.label} — shaped JSON', style: KsTextStyles.h3)),
              const KsMockBadge(),
            ]),
            const SizedBox(height: 10),
            SelectableText(
              const JsonEncoder.withIndent('  ').convert(_shaped),
              style: KsTextStyles.caption.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: KsTextStyles.bodyMedium(size: 13)),
                const SizedBox(height: 2),
                const KsMockBadge(),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: KsColors.terracotta),
            )
          else if (_shaped != null)
            TextButton(onPressed: _viewJson, child: const Text('View JSON')),
          Switch(value: _enabled, onChanged: _toggle, activeThumbColor: KsColors.terracotta),
        ],
      ),
    );
  }
}
