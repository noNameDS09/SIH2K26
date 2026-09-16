import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/artisan.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_trade_record_bars.dart';
import '../widgets/ks_spoken_empty_state.dart';

/// Stage 6 — sales for this artisan, spoken first, plus the Trade Record.
/// Real `GET /v1/money` (`apps/api/.../routers/sales.py`) returns
/// `{sales, total_inr, count, empty, spoken, trade_record}` — one running
/// total, no pending/this-month breakdown exists server-side, so this
/// screen no longer shows those (previously fabricated) figures. `spoken`
/// is a server-composed, already-localised line — used directly instead
/// of building an English-only sentence client-side.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  bool _loading = true;
  int _total = 0;
  List<Map<String, dynamic>> _sales = [];
  String _spokenLine = 'No sales yet.';
  TradeRecord _tradeRecord = const TradeRecord();
  bool _spoken = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.money();
    if (!mounted) return;
    setState(() {
      _sales = ((data?['sales'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      _total = (data?['total_inr'] as num?)?.toInt() ?? 0;
      _spokenLine = data?['spoken'] as String? ?? 'No sales yet.';
      _tradeRecord = TradeRecord.fromJson(data?['trade_record'] as Map<String, dynamic>?);
      _loading = false;
    });
    final provider = context.read<SessionProvider>();
    if (!_spoken && provider.speakScreensEnabled) {
      _spoken = true;
      provider.speakText(_spokenLine);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'Earnings'),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B4D3E), Color(0xFF2D7A5A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Sales',
                                    style: KsTextStyles.label(color: KsColors.white.withAlpha(180), size: 11)),
                                const SizedBox(height: 8),
                                Text('₹$_total',
                                    style: KsTextStyles.price(color: KsColors.white, size: 36)),
                                const SizedBox(height: 8),
                                Text('${_sales.length} sale${_sales.length == 1 ? '' : 's'}',
                                    style: KsTextStyles.body(color: KsColors.white.withAlpha(180), size: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_sales.isEmpty) ...[
                            KsSpokenEmptyState(
                              icon: Icons.receipt_long_outlined,
                              text: _spokenLine,
                            ),
                          ] else ...[
                            Text('Recent Transactions',
                                style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                            const SizedBox(height: 12),
                            ..._sales.map((s) => _TransactionTile(
                                  title: (s['craft'] as String?)?.trim().isNotEmpty == true
                                      ? s['craft'] as String
                                      : 'Sale',
                                  amount: '₹${(s['amount'] as num?)?.toInt() ?? 0}',
                                )),
                          ],
                          const SizedBox(height: 24),

                          KsTradeRecordBars(record: _tradeRecord),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
          KsBottomNav(
            currentIndex: 3,
            onTap: (i) => KsBottomNav.navigate(context, i),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String amount;
  const _TransactionTile({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KsColors.paleGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_downward, color: KsColors.deepGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: KsTextStyles.body(size: 13))),
        Text('+$amount', style: KsTextStyles.price(color: KsColors.deepGreen, size: 14)),
      ]),
    );
  }
}
