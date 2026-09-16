import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_cards.dart';
import '../widgets/ks_stage_progress.dart';
import '../widgets/ks_qr_card.dart';
import '../widgets/ks_adapter_toggle.dart';
import '../widgets/ks_mock_badge.dart';
import '../../services/session_provider.dart';

class Screen5Outward extends StatefulWidget {
  const Screen5Outward({super.key});

  @override
  State<Screen5Outward> createState() => _Screen5OutwardState();
}

class _Screen5OutwardState extends State<Screen5Outward> {
  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _message('Action completed.');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showVoiceNote() {
    bool playing = false;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: KsColors.greenSoft,
                  child: Icon(Icons.record_voice_over_outlined, color: KsColors.greenDark, size: 30),
                ),
                const SizedBox(height: 12),
                Text('Hindi Voice Note', style: KsTextStyles.section),
                const SizedBox(height: 4),
                Text('Artisan provenance story • 00:42', style: KsTextStyles.caption),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: playing ? .45 : 0,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: KsColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation(KsColors.terracotta),
                ),
                const SizedBox(height: 16),
                IconButton.filled(
                  onPressed: () => setSheetState(() => playing = !playing),
                  style: IconButton.styleFrom(
                    backgroundColor: KsColors.terracotta,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(58, 58),
                  ),
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                const SizedBox(height: 8),
                Text(playing ? 'Playing…' : 'Tap to play', style: KsTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showA4Card() => _showInfo('Printable A4 Card', 'A4 product card preview is ready with QR, artisan details and provenance.');

  void _showStoryCard() => _showInfo('HD Story Card', 'HD story card preview is ready for retail buyers and marketplace listings.');

  Future<void> _copyLink(String? url) async {
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    _message('Link copied — share it any way you like.');
  }

  @override
  Widget build(BuildContext context) {
    final ks = KsStrings.of(context);
    final provider = context.watch<SessionProvider>();
    final listing = provider.listing;
    final publicUrl = listing?['publicUrl'] as String? ?? listing?['public_url'] as String?;
    final qrUrl = listing?['qrUrl'] as String? ?? listing?['qr_url'] as String?;
    final title = listing?['title_en'] as String?;
    final prices = listing?['prices'];
    final price = prices is Map ? (prices['listed'] as num?)?.toInt() : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KsAppHeader(
                title: 'KalaSetu',
                onBack: () => context.go(AppRoutes.approval),
              ),
              const SizedBox(height: 12),
              const KsStageProgress(stage: 5, label: 'OUTWARD MULTI-CHANNEL DISTRIBUTION'),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  text: '${ks.publishedReadyTo} ',
                  style: KsTextStyles.display,
                  children: [
                    TextSpan(
                      text: ks.sell,
                      style: KsTextStyles.displayAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(KsStrings.of(context).publishedSubtitle, style: KsTextStyles.body()),
              const SizedBox(height: 14),
              KsCard(
                child: _ListingCard(
                  title: title,
                  price: price,
                  onTap: () => _showInfo('Listing', 'ID: ${provider.listingId ?? '—'}'),
                ),
              ),
              const SizedBox(height: 16),
              Text('QR & public link', style: KsTextStyles.section),
              const SizedBox(height: 10),
              KsQrCard(qrUrl: qrUrl, publicUrl: publicUrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(ks.directWhatsAppPack, style: KsTextStyles.section),
                  const Spacer(),
                  KsPill(
                    text: ks.instantReach,
                    icon: Icons.bolt_rounded,
                    green: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              KsCard(
                child: Column(
                  children: [
                    _ChannelHero(onTap: () => _showInfo('Chat Toolkit', 'Catalog and audio story are bundled here for direct buyer conversations.')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.qr_code_2_rounded, label: ks.printableA4, onTap: _showA4Card)),
                        const SizedBox(width: 7),
                        Expanded(child: _QuickAction(icon: Icons.style_outlined, label: ks.hdStoryCard, onTap: _showStoryCard)),
                        const SizedBox(width: 7),
                        Expanded(child: _QuickAction(icon: Icons.record_voice_over_outlined, label: ks.voiceNoteLabel, onTap: _showVoiceNote)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    KsActionButton(
                      label: 'Copy link to share',
                      icon: Icons.copy_rounded,
                      onPressed: () => _copyLink(publicUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(ks.marketplaceAdapters, style: KsTextStyles.section),
                  const Spacer(),
                  const KsMockBadge(),
                ],
              ),
              const SizedBox(height: 10),
              KsCard(
                child: Column(
                  children: [
                    KsAdapterToggle(channel: 'gem', label: 'GeM Portal (Govt e-Market)', listingId: provider.listingId),
                    const Divider(height: 16),
                    KsAdapterToggle(channel: 'ondc', label: 'ONDC Open Commerce', listingId: provider.listingId),
                    const Divider(height: 16),
                    KsAdapterToggle(channel: 'indiahandmade', label: 'IndiaHandmade', listingId: provider.listingId),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(ks.clusterFieldVerification, style: KsTextStyles.section),
              const SizedBox(height: 10),
              KsCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: KsColors.terracottaSoft,
                          child: Text('ST',
                              style: TextStyle(
                                  color: KsColors.terracotta,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'S. Trivedi\nIndore West Craft Cluster Officer • Seal #771',
                            style: KsTextStyles.caption.copyWith(
                              color: KsColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Contact officer',
                          onPressed: () => _showInfo('Cluster Officer', 'S. Trivedi • Indore West Craft Cluster Officer • Seal #771\n\nContact action is ready for integration with the phone/communication plugin.'),
                          icon: const Icon(Icons.phone_outlined,
                              color: KsColors.terracotta),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showInfo('Dispatch Schedule', 'Hub Batch Dispatch is scheduled for tomorrow at 11:30 AM.'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KsColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 19, color: KsColors.terracotta),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${ks.hubBatchDispatch}\n${ks.scheduledForTomorrow}',
                                style: KsTextStyles.caption,
                              ),
                            ),
                            Text(
                              'Tomorrow, 11:30 AM',
                              style: KsTextStyles.caption.copyWith(
                                color: KsColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KsColors.surfaceWarm.withOpacity(.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('”${ks.addProductPrompt}”',
                        style: KsTextStyles.caption.copyWith(
                            color: KsColors.ink,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(ks.bhashiniNlpNote,
                        style: KsTextStyles.caption),
                    const SizedBox(height: 10),
                    KsActionButton(
                      label: ks.createAnotherProduct,
                      icon: Icons.add_circle_outline,
                      onPressed: () {
                        // Fresh server-issued listingId for the new draft —
                        // never reuse the just-published one.
                        provider.reset();
                        context.go(AppRoutes.capture);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KsBottomNav(
        currentIndex: 1,
        onTap: (index) => KsBottomNav.navigate(context, index),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.onTap, this.title, this.price});
  final VoidCallback onTap;
  final String? title;
  final int? price;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF9C5935), Color(0xFF563022)],
              ),
            ),
            child: const Icon(Icons.spa_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title ?? 'Your listing',
                          style: KsTextStyles.section.copyWith(fontSize: 12)),
                    ),
                    const KsPill(text: 'Published', green: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Signed and ready to share — see QR below',
                    style: KsTextStyles.caption),
                const SizedBox(height: 8),
                Text(
                  price != null ? '₹$price' : 'Price not set',
                  style: KsTextStyles.caption.copyWith(
                      color: KsColors.terracotta,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelHero extends StatelessWidget {
  const _ChannelHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: KsColors.green,
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'High-Converting Chat Toolkit\nSend catalog, invoice & audio story to retail buyers',
              style: KsTextStyles.caption.copyWith(
                color: KsColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KsColors.surfaceWarm,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: KsColors.terracotta),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: KsTextStyles.caption.copyWith(fontSize: 8)),
            ],
          ),
        ),
      ),
    );
  }
}

