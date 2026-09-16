import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'Insights'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Trend Agent card
                  _AgentCard(
                    agentLabel: 'TREND AGENT — MARKET DATA',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: _DataChip(label: 'Peak Windows', value: 'Oct–Dec')),
                          const SizedBox(width: 10),
                          Expanded(child: _DataChip(label: 'Top Hotspots', value: 'Delhi NCR • Mumbai')),
                        ]),
                        const SizedBox(height: 14),
                        const _TrendSparkline(),
                        const SizedBox(height: 12),
                        Text(
                          'Handloom demand peaks in festive season. Your cluster sees 3.2x higher sales in Q4.',
                          style: KsTextStyles.body(size: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Market heatmap
                  _AgentCard(
                    agentLabel: 'GEOGRAPHY AGENT',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Buyer Regions',
                            style: KsTextStyles.bodyMedium(size: 13)),
                        const SizedBox(height: 12),
                        ...const [
                          ('Delhi NCR', 0.9, '₹12,400'),
                          ('Mumbai', 0.7, '₹8,200'),
                          ('Bangalore', 0.5, '₹5,600'),
                          ('Hyderabad', 0.4, '₹4,100'),
                        ].map((r) => _RegionBar(name: r.$1, ratio: r.$2, value: r.$3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Opportunity Agent card
                  _AgentCard(
                    agentLabel: 'OPPORTUNITY AGENT',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bundle Opportunity',
                            style: KsTextStyles.bodyMedium()),
                        const SizedBox(height: 6),
                        Text(
                          'This product sells 40% better when bundled with a matching piece.',
                          style: KsTextStyles.body(size: 13),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [KsColors.terracotta, Color(0xFF6B9E3C)],
                            ),
                          ),
                          child: Row(children: [
                            Expanded(flex: 60, child: Container()),
                            Expanded(flex: 40, child: Container()),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('Single: 60%', style: KsTextStyles.label(color: KsColors.terracotta, size: 9)),
                          const Spacer(),
                          Text('Bundle: 40%', style: KsTextStyles.label(color: KsColors.deepGreen, size: 9)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          KsBottomNav(
            currentIndex: 4,
            onTap: (i) => _navTap(context, i),
          ),
        ],
      ),
    );
  }

  void _navTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go(AppRoutes.home); break;
      case 1: context.go(AppRoutes.capture); break;
      case 2: context.go(AppRoutes.shop); break;
      case 3: context.go(AppRoutes.money); break;
      case 4: break;
    }
  }
}

class _AgentCard extends StatelessWidget {
  final String agentLabel;
  final Widget child;
  const _AgentCard({required this.agentLabel, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(agentLabel, style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

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
    return SizedBox(
      height: 56,
      child: CustomPaint(
        size: const Size(double.infinity, 56),
        painter: _SparklinePainter(),
      ),
    );
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
    canvas.drawPath(line, Paint()
      ..color = KsColors.terracotta..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RegionBar extends StatelessWidget {
  final String name;
  final double ratio;
  final String value;
  const _RegionBar({required this.name, required this.ratio, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 80, child: Text(name, style: KsTextStyles.body(size: 12))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: KsColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(KsColors.terracotta),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: KsTextStyles.price(color: KsColors.terracotta, size: 11)),
      ]),
    );
  }
}
