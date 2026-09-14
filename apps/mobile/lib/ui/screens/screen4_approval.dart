import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_cards.dart';
import '../widgets/ks_progress_bar.dart';

class Screen4Approval extends StatefulWidget {
  const Screen4Approval({super.key});

  @override
  State<Screen4Approval> createState() => _Screen4ApprovalState();
}

class _Screen4ApprovalState extends State<Screen4Approval> {
  bool verified = true;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _editDetails() {
    setState(() => verified = !verified);
    _message(verified
        ? 'Product details verified.'
        : 'Edit mode enabled — details can be reviewed.');
  }

  void _showListenSheet(String title, String message) {
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
              Text(message, style: KsTextStyles.body),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KsColors.terracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _message('Audio playback started.'),
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

  void _showListingDetails() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verified Card'),
        content: const Text(
          'Listing #KS-2025-IND-8942\n\nThis card contains the cluster verification, artisan identity, provenance and pricing details prepared for publishing.',
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

  void _showGeoProof() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geotag Proof'),
        content: const Text(
          'Chanderi Weaver Cluster, Ashoknagar MP\nCoordinates: 24.0°\n\nCluster proof is approved and attached to this product card.',
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
                title: 'Artisan Approval',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 12),
              const KsProgressBar(
                current: 4,
                total: 5,
                label: 'STAGE 4 — ARTISAN APPROVAL & LISTING',
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Verify Your ',
                        style: KsTextStyles.display,
                        children: [
                          TextSpan(
                            text: 'Product Card',
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
                        'Listen to the translated product-card summary before publishing.',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: KsPill(
                          text: verified ? 'Listen' : 'Review',
                          icon: Icons.volume_up_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(KsStrings.approvalSubtitle, style: KsTextStyles.body),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KsPill(
                    text: verified ? 'Listing Agent: Verified' : 'Needs Review',
                    icon: verified ? Icons.check_circle : Icons.info_outline,
                    green: verified,
                  ),
                  const KsPill(
                    text: 'Price Agent: ₹3,850 Optimal',
                    icon: Icons.sell_outlined,
                    green: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _VerifiedHeader(onTap: _showListingDetails),
              const SizedBox(height: 14),
              _ArtisanIdentity(),
              const SizedBox(height: 12),
              _ProductVisual(),
              const SizedBox(height: 14),
              _ProvenanceCard(onListen: () => _showListenSheet(
                'Heritage Provenance Story',
                'Woven painstakingly on a traditional pit-loom using fine mulberry silk warp and hand-spun zari motifs.',
              )),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _StatCard(label: 'MATERIAL', value: 'Pure Silk Zari', note: 'Natural Dye')),
                  SizedBox(width: 7),
                  Expanded(child: _StatCard(label: 'CRAFT TIME', value: '14 Days', note: 'Pit-Loom Hours')),
                  SizedBox(width: 7),
                  Expanded(child: _StatCard(label: 'PRICE', value: '₹3,850', note: 'Fair Wage Model')),
                ],
              ),
              const SizedBox(height: 12),
              _GeoCard(onTap: _showGeoProof),
              const SizedBox(height: 14),
              KsActionButton(
                label: 'Approve & Publish',
                icon: Icons.publish_rounded,
                onPressed: () => context.go(AppRoutes.distribute),
              ),
              const SizedBox(height: 8),
              KsActionButton(
                label: verified ? 'Edit Details' : 'Mark Verified',
                icon: verified ? Icons.edit_outlined : Icons.check,
                secondary: true,
                onPressed: _editDetails,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Your GI signature & craft copyright remain 100% owned by your guild.',
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
  const _VerifiedHeader({required this.onTap});
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
            'KALASETU VERIFIED CARD\nCluster-Grade Handcrafted Certificate',
            style: KsTextStyles.caption.copyWith(
              color: KsColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Text('#KS-2025-IND-8942',
                style: TextStyle(
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
              'Devi Ram Weavers Guild\nChanderi Cluster, MP • Master Weaver (24 yrs exp)',
              style: KsTextStyles.caption.copyWith(
                color: KsColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const KsPill(text: 'GI Certified', green: true),
        ],
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  const _ProvenanceCard({required this.onListen});
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
              Text('HERITAGE PROVENANCE STORY', style: KsTextStyles.label),
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
            '“Woven painstakingly on a traditional pit-loom using fine mulberry silk warp and hand-spun zari motifs. Every woven motif reflects centuries of Malwa craftsmanship passed down through four unbroken generations.”',
            style: KsTextStyles.body.copyWith(
              fontStyle: FontStyle.italic,
              color: KsColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text('AI Translation Model: Bhashini Indic-v4 • Verified',
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
          Text(label, style: KsTextStyles.label),
          const SizedBox(height: 5),
          Text(value, style: KsTextStyles.section.copyWith(fontSize: 12)),
          Text(note, style: KsTextStyles.caption),
        ],
      ),
    );
  }
}

class _GeoCard extends StatelessWidget {
  const _GeoCard({required this.onTap});
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
        child: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, size: 30, color: KsColors.ink),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Geotag Proof: 24.0°\nChanderi Weaver Cluster, Ashoknagar MP',
                style: TextStyle(fontSize: 10, height: 1.35),
              ),
            ),
            KsPill(text: 'Approved', icon: Icons.check, green: true),
          ],
        ),
      ),
    );
  }
}
