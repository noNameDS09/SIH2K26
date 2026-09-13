import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';
import '../l10n/ks_strings.dart';

class Screen3Intelligence extends StatefulWidget {
  const Screen3Intelligence({super.key});

  @override
  State<Screen3Intelligence> createState() => _Screen3IntelligenceState();
}

class _Screen3IntelligenceState extends State<Screen3Intelligence> {
  int _selectedBand = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SessionProvider>();
      // If cataloger isn't done yet, finalize with one more turn
      if (!provider.isDone) {
        await provider.stopRecordingAndSubmit(langCode: 'mr-IN');
      }
    });
  }

  Map<String, int> get _prices {
    final listing = context.read<SessionProvider>().listing;
    final raw = listing?['prices'];
    if (raw is Map) {
      return {
        'floor': (raw['floor'] as num?)?.toInt() ?? 3800,
        'recommended': (raw['recommended'] as num?)?.toInt() ?? 5200,
        'ceiling': (raw['ceiling'] as num?)?.toInt() ?? 7500,
      };
    }
    return {'floor': 3800, 'recommended': 5200, 'ceiling': 7500};
  }

  void _selectBand(int index, String label) {
    setState(() => _selectedBand = index);
    _showSnack('$label ${KsStrings.of(context).priceBandSelected}');
  }

  Future<void> _toggleAudio() async {
    final provider = context.read<SessionProvider>();
    final listing = provider.listing;
    final text = (listing?['title_mr'] as String?) ??
        (listing?['title_en'] as String?) ??
        'तुमची यादी तयार आहे';
    await provider.speakText(text, langCode: 'mr-IN');
  }

  void _copyHashtag(String tag) async {
    await Clipboard.setData(ClipboardData(text: tag));
    if (mounted) _showSnack('${KsStrings.of(context).hashtagCopied}: $tag');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: KsTextStyles.body(color: KsColors.white, size: 13)),
        backgroundColor: KsColors.terracotta,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ks = KsStrings.of(context);
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final listing = provider.listing;
        final prices = _prices;
        final titleMr = (listing?['title_mr'] as String?) ?? 'हस्तनिर्मित बांस-जरी कापड';
        final titleEn = (listing?['title_en'] as String?) ?? 'Handcrafted Bamboo-Zari Cotton Fabric';
        final cluster = (listing?['cluster'] as String?) ?? 'Maheshwar, MP';

        return Scaffold(
          backgroundColor: KsColors.background,
          appBar: KsAppHeader(title: ks.intelligenceReview),
          body: provider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2.5),
                      const SizedBox(height: 16),
                      Text(provider.statusMessage ?? 'AI विश्लेषण…',
                          style: KsTextStyles.label(color: KsColors.terracotta, size: 13)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _StageHeader(step3Label: ks.step3Of5),
                      const SizedBox(height: 10),
                      const KsProgressBar(totalSteps: 5, currentStep: 3),
                      const SizedBox(height: 12),
                      _StageBadge(label: ks.stage3Badge),
                      const SizedBox(height: 20),
                      _HeroPills(confidenceLabel: ks.confidencePill, agentLabel: ks.multiAgentPill),
                      const SizedBox(height: 16),
                      Text(ks.craftIntelligence, style: KsTextStyles.editorial(size: 24)),
                      const SizedBox(height: 6),
                      Text(ks.analysisSubtext, style: KsTextStyles.body()),
                      const SizedBox(height: 24),

                      // ── Listing Agent ─────────────────────────────────────
                      _AgentCard(
                        agentLabel: ks.listingAgent,
                        statusLabel: ks.specsExtracted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(ks.seoTitleLabel),
                            const SizedBox(height: 6),
                            _SeoTitleBox(titleMr: titleMr, titleEn: titleEn),
                            const SizedBox(height: 16),
                            _AudioSummaryRow(
                              label: ks.audioSummary,
                              playing: provider.isPlayingAudio,
                              onTap: _toggleAudio,
                            ),
                            const SizedBox(height: 12),
                            _HashtagRow(onCopy: _copyHashtag),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Trend Agent ───────────────────────────────────────
                      _AgentCard(
                        agentLabel: ks.trendAgent,
                        statusLabel: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _DataChip(label: ks.peakWindows, value: ks.peakValue)),
                                const SizedBox(width: 10),
                                Expanded(child: _DataChip(label: ks.topHotspots, value: ks.hotspotsValue)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const _TrendSparkline(),
                            const SizedBox(height: 12),
                            Text(ks.trendBody, style: KsTextStyles.body(size: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Fair-Price Agent ──────────────────────────────────
                      _AgentCard(
                        agentLabel: ks.fairPriceAgent,
                        statusLabel: ks.fairWageCertified,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CostRow(label: ks.rawMaterial, amount: '₹820'),
                            _CostRow(label: ks.labourCost, amount: '₹1,960'),
                            _CostRow(label: ks.finishing, amount: '₹320'),
                            const SizedBox(height: 14),
                            _RecommendedBox(
                              price: '₹${prices['recommended']!}',
                              targetLabel: ks.recommendedTarget,
                              marginLabel: ks.netMargin,
                              guaranteedLabel: ks.guaranteed,
                            ),
                            const SizedBox(height: 14),
                            _PriceBandSelector(
                              selected: _selectedBand,
                              prices: prices,
                              lowestLabel: ks.lowestPrice,
                              recLabel: ks.recommendedPrice,
                              highestLabel: ks.highestPrice,
                              onSelect: _selectBand,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Business Opportunity Agent ─────────────────────────
                      _AgentCard(
                        agentLabel: ks.opportunityAgent,
                        statusLabel: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ks.bundleTitle, style: KsTextStyles.bodyMedium()),
                            const SizedBox(height: 6),
                            Text(ks.bundleBody, style: KsTextStyles.body(size: 13)),
                            const SizedBox(height: 14),
                            const _GmvBar(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Payload Preview ────────────────────────────────────
                      _PayloadPreview(ks: ks, cluster: cluster),
                      const SizedBox(height: 24),

                      // ── CTA ───────────────────────────────────────────────
                      _ReviewCtaButton(
                        label: ks.reviewCta,
                        onTap: () => _showSnack(ks.readyToVerify),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(ks.step3Of5,
                            style: KsTextStyles.label(color: KsColors.brown3, size: 11)),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ─── Stage header / badge ──────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final String step3Label;
  const _StageHeader({required this.step3Label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('STAGE 03 / 05', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
        const Spacer(),
        Text('KALASETU AI PIPELINE', style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  const _StageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 7, height: 7,
            decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: KsTextStyles.label(color: KsColors.mainText, size: 11)),
      ],
    );
  }
}

// ─── Hero pills ───────────────────────────────────────────────────────────────

class _HeroPills extends StatelessWidget {
  final String confidenceLabel;
  final String agentLabel;
  const _HeroPills({required this.confidenceLabel, required this.agentLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(label: confidenceLabel, accent: true),
        const SizedBox(width: 8),
        _Pill(label: agentLabel, accent: false),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool accent;
  const _Pill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? KsColors.terracotta : KsColors.peach3,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: KsTextStyles.label(color: accent ? KsColors.white : KsColors.terracotta, size: 10)),
    );
  }
}

// ─── Agent card ───────────────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  final String agentLabel;
  final String? statusLabel;
  final Widget child;
  const _AgentCard({required this.agentLabel, this.statusLabel, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: KsColors.surface1, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(agentLabel, style: KsTextStyles.label(color: KsColors.terracotta, size: 10))),
              if (statusLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: KsColors.paleGreen, borderRadius: BorderRadius.circular(10)),
                  child: Text(statusLabel!, style: KsTextStyles.label(color: KsColors.deepGreen, size: 9)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Listing Agent internals ──────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: KsTextStyles.label(color: KsColors.brown3, size: 9));
}

class _SeoTitleBox extends StatelessWidget {
  final String titleMr;
  final String titleEn;
  const _SeoTitleBox({required this.titleMr, required this.titleEn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KsColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KsColors.peach3, width: 1),
      ),
      child: Text(
        '$titleMr — $titleEn | GI Tag',
        style: GoogleFonts.plusJakartaSans(
            color: KsColors.mainText, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
      ),
    );
  }
}

class _AudioSummaryRow extends StatelessWidget {
  final String label;
  final bool playing;
  final VoidCallback onTap;
  const _AudioSummaryRow({required this.label, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: KsColors.peach3, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(playing ? Icons.pause_circle : Icons.play_circle_filled,
                color: KsColors.terracotta, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: KsTextStyles.bodyMedium(size: 12))),
            Container(
              width: 30, height: 20,
              decoration: BoxDecoration(color: KsColors.white, borderRadius: BorderRadius.circular(4)),
              child: CustomPaint(painter: _WaveformPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = KsColors.terracotta..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    const bars = [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 0.3, 0.7, 0.5];
    final w = size.width / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final x = i * w + w / 2;
      final h = bars[i] * size.height;
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HashtagRow extends StatelessWidget {
  final void Function(String) onCopy;
  const _HashtagRow({required this.onCopy});

  static const _tags = ['#HandloomIndia', '#GITag', '#ZariCraft', '#VocalForLocal'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _tags.map((tag) => GestureDetector(
        onTap: () => onCopy(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: KsColors.surface3, borderRadius: BorderRadius.circular(20)),
          child: Text(tag, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
        ),
      )).toList(),
    );
  }
}

// ─── Trend Agent internals ────────────────────────────────────────────────────

class _DataChip extends StatelessWidget {
  final String label;
  final String value;
  const _DataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: KsColors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
          const SizedBox(height: 4),
          Text(value, style: KsTextStyles.bodyMedium(size: 12)),
        ],
      ),
    );
  }
}

class _TrendSparkline extends StatelessWidget {
  const _TrendSparkline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 56, child: CustomPaint(size: const Size(double.infinity, 56), painter: _SparklinePainter()));
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.2, 0.3, 0.25, 0.4, 0.6, 0.75, 0.9, 1.0, 0.85, 0.7, 0.5, 0.8];
    final dx = size.width / (values.length - 1);
    final fill = Path();
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height * (1 - values[i] * 0.8);
      if (i == 0) { fill.moveTo(x, y); line.moveTo(x, y); }
      else { fill.lineTo(x, y); line.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height);
    fill.lineTo(0, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [KsColors.terracotta.withAlpha(60), KsColors.terracotta.withAlpha(0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(line, Paint()..color = KsColors.terracotta..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Fair-Price Agent internals ───────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  final String label;
  final String amount;
  const _CostRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 4, height: 4,
              decoration: const BoxDecoration(color: KsColors.brown4, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: KsTextStyles.body(size: 12))),
          Text(amount, style: KsTextStyles.bodyMedium(size: 13)),
        ],
      ),
    );
  }
}

class _RecommendedBox extends StatelessWidget {
  final String price;
  final String targetLabel;
  final String marginLabel;
  final String guaranteedLabel;
  const _RecommendedBox({required this.price, required this.targetLabel, required this.marginLabel, required this.guaranteedLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KsColors.peach3),
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(targetLabel, style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
            const SizedBox(height: 4),
            Text(price, style: KsTextStyles.price(color: KsColors.terracotta, size: 26)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(marginLabel, style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
            const SizedBox(height: 4),
            Row(children: [
              Text('38%', style: KsTextStyles.price(color: KsColors.green, size: 20)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: KsColors.paleGreen, borderRadius: BorderRadius.circular(8)),
                child: Text(guaranteedLabel, style: KsTextStyles.label(color: KsColors.green, size: 9)),
              ),
            ]),
          ]),
        ],
      ),
    );
  }
}

class _PriceBandSelector extends StatelessWidget {
  final int selected;
  final Map<String, int> prices;
  final String lowestLabel;
  final String recLabel;
  final String highestLabel;
  final void Function(int, String) onSelect;
  const _PriceBandSelector({
    required this.selected, required this.prices,
    required this.lowestLabel, required this.recLabel, required this.highestLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bands = [
      (lowestLabel, '₹${prices['floor']!}'),
      (recLabel, '₹${prices['recommended']!}'),
      (highestLabel, '₹${prices['ceiling']!}'),
    ];
    return Row(
      children: List.generate(3, (i) {
        final active = i == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i, bands[i].$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? KsColors.terracotta : KsColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active ? KsColors.terracotta : KsColors.peach3),
                ),
                child: Column(children: [
                  Text(bands[i].$1, style: KsTextStyles.label(
                      color: active ? KsColors.white.withAlpha(180) : KsColors.brown3, size: 8)),
                  const SizedBox(height: 4),
                  Text(bands[i].$2, style: KsTextStyles.price(
                      color: active ? KsColors.white : KsColors.mainText, size: 15)),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Business Opportunity internals ──────────────────────────────────────────

class _GmvBar extends StatelessWidget {
  const _GmvBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: KsColors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GMV POTENTIAL', style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
            const SizedBox(height: 4),
            Text('₹18,750 / season',
                style: KsTextStyles.bodyMedium(size: 13, color: KsColors.terracotta)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: KsColors.peach3, borderRadius: BorderRadius.circular(8)),
            child: Text('+₹250 bundle', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
          ),
        ],
      ),
    );
  }
}

// ─── Payload Preview ──────────────────────────────────────────────────────────

class _PayloadPreview extends StatelessWidget {
  final KsStrings ks;
  final String cluster;
  const _PayloadPreview({required this.ks, required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: KsColors.mainText, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ks.payloadTitle, style: KsTextStyles.label(color: KsColors.peach3, size: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KsColors.green.withAlpha(50), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KsColors.paleGreen.withAlpha(80)),
                ),
                child: Text(ks.readyToVerify, style: KsTextStyles.label(color: KsColors.paleGreen, size: 9)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PayloadRow(ks.originCluster, cluster),
          _PayloadRow(ks.weaveTechnique, 'Extra-weft (Jamdani variant)'),
          _PayloadRow(ks.dispatchSla, '5 working days'),
          _PayloadRow(ks.channelsMapped, 'GeMB2B • Amazon.in • Etsy'),
        ],
      ),
    );
  }
}

class _PayloadRow extends StatelessWidget {
  final String label;
  final String value;
  const _PayloadRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110,
              child: Text(label, style: KsTextStyles.label(color: KsColors.brown4, size: 10))),
          Expanded(child: Text(value, style: KsTextStyles.body(color: KsColors.peach2, size: 12))),
        ],
      ),
    );
  }
}

// ─── Review CTA ───────────────────────────────────────────────────────────────

class _ReviewCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ReviewCtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: KsColors.terracotta, borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: KsColors.terracotta.withAlpha(70), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined, color: KsColors.white, size: 18),
            const SizedBox(width: 10),
            Text(label, style: KsTextStyles.cta(size: 15)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, color: KsColors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
