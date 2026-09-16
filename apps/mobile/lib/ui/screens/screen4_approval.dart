import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_cards.dart';
import '../widgets/ks_progress_bar.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';

class Screen4Approval extends StatefulWidget {
  const Screen4Approval({super.key});

  @override
  State<Screen4Approval> createState() => _Screen4ApprovalState();
}

class _Screen4ApprovalState extends State<Screen4Approval> {
  bool verified = true;
  bool _isPublishing = false;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _publish(SessionProvider sp) async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);
    final id = sp.listingId ?? 'demo-${DateTime.now().millisecondsSinceEpoch}';
    await ApiService.signListing(id);
    if (!mounted) return;
    setState(() => _isPublishing = false);
    context.go(AppRoutes.distribute);
  }

  void _editDetails() {
    setState(() => verified = !verified);
    _message(verified
        ? 'Product details verified.'
        : 'Edit mode enabled — details can be reviewed.');
  }

  void _showListenSheet(String title, String message, {VoidCallback? onPlay}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: KsColors.terracottaSoft,
                    child: Icon(Icons.volume_up_outlined, color: KsColors.terracotta),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: KsTextStyles.section)),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message, style: KsTextStyles.body()),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KsColors.terracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onPlay ?? () => _message('Audio playback started.'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play Audio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showListingDetails(String listingIdStr) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verified Card'),
        content: Text(
          'Listing $listingIdStr\n\nThis card contains the cluster verification, artisan identity, provenance and pricing details prepared for publishing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _message('Listing ID copied to clipboard.');
            },
            child: const Text('Copy ID'),
          ),
        ],
      ),
    );
  }

  void _showGeoProof(String cluster) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geotag Proof'),
        content: Text(
          '$cluster\n\nCluster proof is approved and attached to this product card.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _message('Geotag proof marked as reviewed.');
            },
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SessionProvider>();
    final listing = sp.listing;

    final cluster = listing?['cluster'] as String? ?? 'Chanderi Cluster, MP';
    final titleEn = listing?['title_en'] as String? ?? 'Heritage Craft Product';
    final descEn = listing?['desc_en'] as String? ??
        'Woven painstakingly on a traditional pit-loom using fine mulberry silk warp and hand-spun zari motifs.';
    final prices = listing?['prices'];
    final listedPrice = prices is Map ? prices['listed'] : null;
    final priceNum = (listedPrice as num?)?.toInt() ??
        (prices is Map ? prices['recommended'] as num? : null)?.toInt();
    final priceStr = priceNum != null ? '₹$priceNum' : '₹3,850';
    final hasCustomPrice = listedPrice is num;
    final imageBytes = sp.enhancedImageBytes ?? sp.capturedImageBytes;
    final rawId = sp.listingId;
    final listingIdStr = rawId != null
        ? '#KS-${rawId.replaceFirst('listing-', '').substring(0, 8).toUpperCase()}'
        : '#KS-2025-IND-8942';

    final ks = KsStrings.of(context);

    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KsAppHeader(
                title: ks.approvalAppHeader,
                onBack: () => context.go('/intelligence'),
              ),
              const SizedBox(height: 12),
              const KsProgressBar(
                currentStep: 4,
                totalSteps: 5,
                label: 'STAGE 4 — ARTISAN APPROVAL & LISTING',
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '${ks.verifyYour} ',
                        style: KsTextStyles.display,
                        children: [
                          TextSpan(
                            text: ks.productCard,
                            style: KsTextStyles.displayAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showListenSheet(
                        'Product Card Audio',
                        '$titleEn. $descEn',
                        onPlay: () => sp.speakText('$titleEn. $descEn'),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: KsPill(
                          text: verified ? ks.listenLabel : ks.reviewLabel,
                          icon: Icons.volume_up_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(KsStrings.of(context).approvalSubtitle, style: KsTextStyles.body()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KsPill(
                    text: verified ? ks.listingAgentVerified : ks.needsReview,
                    icon: verified ? Icons.check_circle : Icons.info_outline,
                    green: verified,
                  ),
                  KsPill(
                    text: hasCustomPrice
                        ? 'Artisan price: $priceStr'
                        : 'Price Agent: $priceStr Optimal',
                    icon: Icons.sell_outlined,
                    green: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _VerifiedHeader(
                listingIdStr: listingIdStr,
                onTap: () => _showListingDetails(listingIdStr),
              ),
              const SizedBox(height: 14),
              _ArtisanIdentity(cluster: cluster),
              const SizedBox(height: 12),
              _ProductVisual(imageBytes: imageBytes),
              const SizedBox(height: 14),
              _ProvenanceCard(
                description: descEn,
                onListen: () => _showListenSheet(
                  'Heritage Provenance Story',
                  descEn,
                  onPlay: () => sp.speakText(descEn),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(label: ks.material, value: ks.handcraftedLabel, note: ks.naturalDyeLabel)),
                  const SizedBox(width: 7),
                  Expanded(child: _StatCard(label: ks.craftTime, value: ks.artisanCraftTime, note: ks.traditionalLabel)),
                  const SizedBox(width: 7),
                  Expanded(child: _StatCard(label: ks.priceLabel, value: priceStr, note: ks.fairWageModel)),
                ],
              ),
              const SizedBox(height: 12),
              _GeoCard(
                cluster: cluster,
                onTap: () => _showGeoProof(cluster),
              ),
              const SizedBox(height: 14),
              KsActionButton(
                label: _isPublishing ? ks.publishingLabel : ks.approveAndPublish,
                icon: Icons.publish_rounded,
                onPressed: _isPublishing ? null : () => _publish(sp),
              ),
              const SizedBox(height: 8),
              KsActionButton(
                label: verified ? ks.editDetails : ks.markVerified,
                icon: verified ? Icons.edit_outlined : Icons.check,
                secondary: true,
                onPressed: _editDetails,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  ks.giSignatureFooter,
                  textAlign: TextAlign.center,
                  style: KsTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KsBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 4) {
            context.go(AppRoutes.distribute);
          } else {
            _message('${_navName(index)} is not part of this two-screen build.');
          }
        },
      ),
    );
  }

  String _navName(int index) {
    const names = ['Studio', 'Kala List', 'Bolo', 'Samuh', 'Bazaar'];
    return names[index];
  }
}

class _VerifiedHeader extends StatelessWidget {
  const _VerifiedHeader({required this.listingIdStr, required this.onTap});
  final String listingIdStr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: KsColors.terracottaSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_rounded,
              color: KsColors.terracotta, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${KsStrings.of(context).kalaSetuVerifiedCard}\n${KsStrings.of(context).clusterGradeCert}',
            style: KsTextStyles.caption.copyWith(
              color: KsColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(listingIdStr,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: KsColors.terracotta)),
          ),
        ),
      ],
    );
  }
}

class _ArtisanIdentity extends StatelessWidget {
  const _ArtisanIdentity({required this.cluster});
  final String cluster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KsColors.surfaceWarm.withOpacity(.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: KsColors.terracottaSoft,
            child: Icon(Icons.person_outline_rounded,
                color: KsColors.terracotta),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Artisan\n$cluster',
              style: KsTextStyles.caption.copyWith(
                color: KsColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          KsPill(text: KsStrings.of(context).giCertified, green: true),
        ],
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({this.imageBytes});
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(imageBytes!, fit: BoxFit.cover),
              const Positioned(
                left: 10,
                top: 10,
                child: KsPill(
                  text: 'Enhanced Image',
                  icon: Icons.auto_fix_high_rounded,
                  green: true,
                ),
              ),
              const Positioned(
                right: 10,
                bottom: 10,
                child: KsPill(
                  text: 'AI Studio',
                  icon: Icons.view_in_ar_outlined,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B2416),
            Color(0xFFB04B24),
            Color(0xFF4B1A11),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _FabricPainter()),
          ),
          const Positioned(
            left: 10,
            top: 10,
            child: KsPill(
              text: '4K Multi-Calibrated',
              icon: Icons.hd_rounded,
              green: true,
            ),
          ),
          const Positioned(
            right: 10,
            bottom: 10,
            child: KsPill(
              text: 'AR 3D Model Attached',
              icon: Icons.view_in_ar_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _FabricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x35F2C28B);
    for (double x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * .7, 0),
        paint..strokeWidth = 2,
      );
    }
    paint.color = const Color(0x22FFD9B0);
    for (double y = 12; y < size.height; y += 24) {
      canvas.drawCircle(Offset(size.width * .32, y), 3, paint);
      canvas.drawCircle(Offset(size.width * .67, y + 8), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProvenanceCard extends StatelessWidget {
  const _ProvenanceCard({required this.description, required this.onListen});
  final String description;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KsColors.surfaceWarm.withOpacity(.62),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(KsStrings.of(context).heritageProvenance, style: KsTextStyles.label()),
              const Spacer(),
              InkWell(
                onTap: onListen,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.volume_up_outlined,
                      size: 17, color: KsColors.terracotta),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '"$description"',
            style: KsTextStyles.body().copyWith(
              fontStyle: FontStyle.italic,
              color: KsColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(KsStrings.of(context).aiTranslationNote,
              style: KsTextStyles.caption),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KsColors.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KsTextStyles.label()),
          const SizedBox(height: 5),
          Text(value, style: KsTextStyles.section.copyWith(fontSize: 12)),
          Text(note, style: KsTextStyles.caption),
        ],
      ),
    );
  }
}

class _GeoCard extends StatelessWidget {
  const _GeoCard({required this.cluster, required this.onTap});
  final String cluster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: KsColors.surfaceWarm,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 30, color: KsColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${KsStrings.of(context).geotagProof}\n$cluster',
                style: const TextStyle(fontSize: 10, height: 1.35),
              ),
            ),
            KsPill(text: KsStrings.of(context).approvedLabel, icon: Icons.check, green: true),
          ],
        ),
      ),
    );
  }
}
