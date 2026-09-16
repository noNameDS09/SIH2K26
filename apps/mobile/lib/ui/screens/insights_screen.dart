import 'package:flutter/material.dart';
import '../../models/advisor_line.dart';
import '../../models/trend.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_trend_line_card.dart';
import '../widgets/ks_advisor_line.dart';
import '../widgets/ks_spoken_empty_state.dart';

/// Stage 6 — advisor history + cluster trend. Previously entirely invented:
/// a fixed "3.2x higher sales in Q4", a Delhi/Mumbai/Bangalore/Hyderabad
/// "Geography Agent" heatmap, and a permanent "sells 40% better bundled"
/// opportunity line, none backed by any call. Now: `GET /v1/trends/current`
/// and `GET /v1/insights` (Agent B's history); the demand-gap "opportunity"
/// line only shows if that rule actually fired for this artisan
/// (`10_VOICE_AND_AGENTS.md`: "do not fill with generic tips").
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _loading = true;
  Trend? _trend;
  List<AdvisorLine> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bundle = await ApiService.insights();
    if (!mounted) return;
    setState(() {
      _trend = bundle.trend;
      _history = bundle.history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final opportunity = _history.where((l) => l.ruleId == 'demand_gap').firstOrNull;

    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'Insights'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: KsColors.terracotta))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          KsTrendLineCard(trend: _trend),
                          const SizedBox(height: 16),

                          if (opportunity != null) ...[
                            _AgentCard(
                              agentLabel: 'OPPORTUNITY',
                              child: KsAdvisorLine(line: opportunity),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Text('Advisor History',
                              style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                          const SizedBox(height: 12),
                          if (_history.isEmpty)
                            const KsSpokenEmptyState(
                              icon: Icons.auto_awesome_outlined,
                              text: 'Nothing to say yet — publish a listing to get advice.',
                            )
                          else
                            ..._history.map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: KsAdvisorLine(line: l),
                                )),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
          KsBottomNav(
            currentIndex: 4,
            onTap: (i) => KsBottomNav.navigate(context, i),
          ),
        ],
      ),
    );
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
