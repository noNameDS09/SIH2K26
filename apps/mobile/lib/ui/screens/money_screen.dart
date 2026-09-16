import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'Earnings'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Balance card
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
                        Text('Total Balance',
                            style: KsTextStyles.label(color: KsColors.white.withAlpha(180), size: 11)),
                        const SizedBox(height: 8),
                        Text('₹24,680',
                            style: KsTextStyles.price(color: KsColors.white, size: 36)),
                        const SizedBox(height: 16),
                        Row(children: [
                          _BalanceChip(label: 'Pending', value: '₹3,200'),
                          const SizedBox(width: 16),
                          _BalanceChip(label: 'This Month', value: '₹8,400'),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monthly breakdown
                  Text('Monthly Earnings',
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                  const SizedBox(height: 12),
                  _EarningsChart(),
                  const SizedBox(height: 24),

                  // Transactions
                  Text('Recent Transactions',
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                  const SizedBox(height: 12),
                  ...const [
                    ('Paithani Saree — ONDC', '₹5,200', '+'),
                    ('Embroidery Bag — GeM', '₹1,800', '+'),
                    ('Platform Fee', '₹104', '-'),
                    ('Warli Art — WhatsApp', '₹3,400', '+'),
                  ].map((t) => _TransactionTile(title: t.$1, amount: t.$2, sign: t.$3)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          KsBottomNav(
            currentIndex: 3,
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
      case 3: break;
      case 4: context.go(AppRoutes.insights); break;
    }
  }
}

class _BalanceChip extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KsTextStyles.label(color: KsColors.white.withAlpha(160), size: 9)),
        const SizedBox(height: 2),
        Text(value, style: KsTextStyles.price(color: KsColors.white, size: 16)),
      ],
    );
  }
}

class _EarningsChart extends StatelessWidget {
  const _EarningsChart();

  static const _months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
  static const _values = [0.4, 0.6, 0.5, 0.75, 0.65, 0.9];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_months.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: _values[i] * 70,
                        decoration: BoxDecoration(
                          color: i == _months.length - 1
                              ? KsColors.terracotta
                              : KsColors.peach3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_months[i], style: KsTextStyles.label(color: KsColors.textSecondary, size: 9)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String amount;
  final String sign;
  const _TransactionTile({required this.title, required this.amount, required this.sign});

  @override
  Widget build(BuildContext context) {
    final isIncome = sign == '+';
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
            color: isIncome ? KsColors.paleGreen : KsColors.peach3,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? KsColors.deepGreen : KsColors.terracotta,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: KsTextStyles.body(size: 13))),
        Text(
          '$sign$amount',
          style: KsTextStyles.price(
            color: isIncome ? KsColors.deepGreen : KsColors.terracotta,
            size: 14,
          ),
        ),
      ]),
    );
  }
}
