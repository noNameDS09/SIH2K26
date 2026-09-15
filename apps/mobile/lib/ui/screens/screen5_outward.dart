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

class Screen5Outward extends StatefulWidget {
  const Screen5Outward({super.key});

  @override
  State<Screen5Outward> createState() => _Screen5OutwardState();
}

class _Screen5OutwardState extends State<Screen5Outward> {
  final Map<String, bool> channels = {
    'GeM Portal (Govt e-Market)': true,
    'ONDC Open Commerce': true,
    'IndiaHandmade': true,
  };

  bool shared = false;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _share() {
    setState(() => shared = true);
    _showInfo('WhatsApp Share', 'The product catalog, invoice and audio story are ready to share with a buyer.');
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

  @override
  Widget build(BuildContext context) {
    final ks = KsStrings.of(context);
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
              const KsProgressBar(
                currentStep: 5,
                totalSteps: 5,
                label: 'STAGE 5 — OUTWARD MULTI-CHANNEL DISTRIBUTION',
              ),
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
              KsCard(child: _ListingCard(onTap: () => _showInfo('Published Listing', 'This listing is live across 3 verified buyer networks.'))),
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
                    _ChannelHero(onTap: () => _showInfo('Chat Toolkit', 'Catalog, invoice and audio story are bundled here for direct buyer conversations.')),
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
                      label: shared ? ks.sharedOnWhatsApp : ks.shareOnWhatsApp,
                      icon: Icons.share_outlined,
                      onPressed: _share,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(ks.marketplaceAdapters, style: KsTextStyles.section),
                  const Spacer(),
                  KsPill(text: ks.oneClickLiveSync),
                ],
              ),
              const SizedBox(height: 10),
              KsCard(
                child: Column(
                  children: channels.keys.map((name) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MarketplaceRow(
                        name: name,
                        enabled: channels[name]!,
                        onChanged: (value) {
                          setState(() => channels[name] = value);
                          _message('$name ${value ? 'enabled' : 'paused'}');
                        },
                      ),
                    );
                  }).toList(),
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
                      onPressed: () => context.go(AppRoutes.capture),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KsBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 1) {
            context.go(AppRoutes.approval);
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

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.onTap});
  final VoidCallback onTap;

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
                      child: Text('Listing #KS-2025-IND-8942',
                          style: KsTextStyles.section.copyWith(fontSize: 12)),
                    ),
                    const KsPill(text: 'Active Now', green: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Live across 3 verified buyer networks',
                    style: KsTextStyles.caption),
                const SizedBox(height: 8),
                Text('Natural Bamboo Vessel & Vases',
                    style: KsTextStyles.section.copyWith(fontSize: 12)),
                Text('₹1,850 • Free Cluster Hub Drop',
                    style: KsTextStyles.caption.copyWith(
                        color: KsColors.terracotta,
                        fontWeight: FontWeight.w700)),
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

class _MarketplaceRow extends StatelessWidget {
  const _MarketplaceRow({
    required this.name,
    required this.enabled,
    required this.onChanged,
  });

  final String name;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final initials = name.startsWith('GeM')
        ? 'G'
        : name.startsWith('ONDC')
            ? 'O'
            : 'IH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: KsColors.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: enabled
                ? KsColors.greenSoft
                : KsColors.surfaceMuted,
            child: Text(initials,
                style: KsTextStyles.caption.copyWith(
                  color: enabled ? KsColors.greenDark : KsColors.textMuted,
                  fontWeight: FontWeight.w800,
                )),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(name,
                style: KsTextStyles.caption.copyWith(
                    color: KsColors.ink, fontWeight: FontWeight.w700)),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeColor: KsColors.terracotta,
          ),
        ],
      ),
    );
  }
}
