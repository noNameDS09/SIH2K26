import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// QR + public link for a signed listing. The PNG is always the server's
/// (`POST /v1/listings/{id}/sign` -> `qrUrl`) — never generated on-device —
/// and the copy-link action is the only "share" surface (no `share_plus`
/// dependency, per the no-build-changes constraint on this app).
class KsQrCard extends StatefulWidget {
  const KsQrCard({super.key, required this.qrUrl, required this.publicUrl});

  final String? qrUrl;
  final String? publicUrl;

  @override
  State<KsQrCard> createState() => _KsQrCardState();
}

class _KsQrCardState extends State<KsQrCard> {
  bool _copied = false;

  Future<void> _copyLink() async {
    final url = widget.publicUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = widget.qrUrl;
    final publicUrl = widget.publicUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KsColors.peach3),
      ),
      child: Column(
        children: [
          if (publicUrl == null) ...[
            Text('Not signed yet — approve the listing to get a QR.',
                style: KsTextStyles.body(size: 12, color: KsColors.textSecondary)),
          ] else ...[
            SizedBox(
              width: 160,
              height: 160,
              child: qrUrl != null
                  ? FutureBuilder<Uint8List?>(
                      future: ApiService.fetchBytes(qrUrl),
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes == null) {
                          return const Center(
                            child: CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2),
                          );
                        }
                        return Image.memory(bytes, fit: BoxFit.contain);
                      },
                    )
                  : const Center(child: Icon(Icons.qr_code_2_rounded, size: 96, color: KsColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            Text(publicUrl, style: KsTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _copyLink,
              icon: Icon(_copied ? Icons.check : Icons.copy_rounded, size: 16),
              label: Text(_copied ? 'Copied' : 'Copy link'),
              style: OutlinedButton.styleFrom(foregroundColor: KsColors.terracotta),
            ),
          ],
        ],
      ),
    );
  }
}
