import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  int _selectedBand = 1;
  bool _useCustomPrice = false;
  String? _customPriceError;
  final _customPriceController = TextEditingController();
  bool _breakdownExpanded = false;

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  Map<String, int> _prices(SessionProvider provider) {
    final raw = provider.listing?['prices'];
    if (raw is Map) {
      return {
        'floor': (raw['floor'] as num?)?.toInt() ?? 3800,
        'recommended': (raw['recommended'] as num?)?.toInt() ?? 5200,
        'ceiling': (raw['ceiling'] as num?)?.toInt() ?? 7500,
      };
    }
    return {'floor': 3800, 'recommended': 5200, 'ceiling': 7500};
  }

  Map<String, dynamic>? _priceBreakdown(SessionProvider provider) {
    final raw = provider.listing?['price_breakdown'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    // Mock breakdown
    return {
      'raw_material': 820,
      'labour_cost': 1960,
      'finishing': 320,
      'overhead': 240,
      'platform_fee': 104,
      'total_cost': 3444,
      'recommended_margin': 0.38,
    };
  }

  void _selectBand(int index, String label) {
    setState(() { _selectedBand = index; _useCustomPrice = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label ${KsStrings.of(context).priceBandSelected}'),
          behavior: SnackBarBehavior.floating),
    );
  }

  void _activateCustomPrice() => setState(() { _useCustomPrice = true; _selectedBand = -1; });

  void _useEnteredPrice() {
    final price = int.tryParse(_customPriceController.text.trim());
    if (price == null || price <= 0) {
      setState(() => _customPriceError = 'Enter a valid price using numbers only.');
      return;
    }
    context.read<SessionProvider>().setListedPrice(price);
    FocusScope.of(context).unfocus();
    setState(() { _customPriceError = null; _useCustomPrice = true; _selectedBand = -1; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹$price will be used on your product card.'),
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ks = KsStrings.of(context);
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final prices = _prices(provider);
        final breakdown = _priceBreakdown(provider);

        return Scaffold(
          backgroundColor: KsColors.background,
          body: Column(
            children: [
              KsAppHeader(
                title: 'Set Your Price',
                onBack: () => context.go(AppRoutes.intelligence),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const KsProgressBar(
                        totalSteps: 7,
                        currentStep: 5,
                        label: 'STAGE 5 — PRICING',
                      ),
                      const SizedBox(height: 20),

                      // Fair Price Agent header
                      Row(children: [
                        Container(width: 7, height: 7,
                            decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('FAIR PRICE AGENT — GeM/ONDC',
                            style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: KsColors.paleGreen, borderRadius: BorderRadius.circular(10)),
                          child: Text(ks.fairWageCertified,
                              style: KsTextStyles.label(color: KsColors.deepGreen, size: 9)),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Recommended price box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: KsColors.surface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KsColors.peach3),
                        ),
                        child: Row(
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ks.recommendedTarget,
                                  style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
                              const SizedBox(height: 4),
                              Text('₹${prices['recommended']!}',
                                  style: KsTextStyles.price(color: KsColors.terracotta, size: 28)),
                            ]),
                            const Spacer(),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(ks.netMargin,
                                  style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('38%', style: KsTextStyles.price(color: KsColors.green, size: 22)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: KsColors.paleGreen, borderRadius: BorderRadius.circular(8)),
                                  child: Text(ks.guaranteed,
                                      style: KsTextStyles.label(color: KsColors.green, size: 9)),
                                ),
                              ]),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cost breakdown collapsible
                      GestureDetector(
                        onTap: () => setState(() => _breakdownExpanded = !_breakdownExpanded),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KsColors.surface1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text('Cost Breakdown',
                                      style: KsTextStyles.bodyMedium(size: 13)),
                                  const Spacer(),
                                  Icon(
                                    _breakdownExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: KsColors.textSecondary,
                                  ),
                                ],
                              ),
                              if (_breakdownExpanded && breakdown != null) ...[
                                const SizedBox(height: 12),
                                _BreakdownRow(label: ks.rawMaterial,
                                    value: '₹${breakdown['raw_material']}'),
                                _BreakdownRow(label: ks.labourCost,
                                    value: '₹${breakdown['labour_cost']}'),
                                _BreakdownRow(label: ks.finishing,
                                    value: '₹${breakdown['finishing']}'),
                                _BreakdownRow(label: 'Overhead',
                                    value: '₹${breakdown['overhead']}'),
                                _BreakdownRow(label: 'Platform Fee',
                                    value: '₹${breakdown['platform_fee']}'),
                                const Divider(height: 16),
                                _BreakdownRow(
                                  label: 'Total Cost',
                                  value: '₹${breakdown['total_cost']}',
                                  bold: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price band selector
                      Text('Select Your Price',
                          style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(3, (i) {
                          final labels = [ks.lowestPrice, ks.recommendedPrice, ks.highestPrice];
                          final keys = ['floor', 'recommended', 'ceiling'];
                          final active = i == _selectedBand;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              child: GestureDetector(
                                onTap: () => _selectBand(i, '₹${prices[keys[i]]!}'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: active ? KsColors.terracotta : KsColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: active ? KsColors.terracotta : KsColors.peach3),
                                  ),
                                  child: Column(children: [
                                    Text(labels[i], style: KsTextStyles.label(
                                        color: active ? KsColors.white.withAlpha(180) : KsColors.brown3,
                                        size: 8)),
                                    const SizedBox(height: 4),
                                    Text('₹${prices[keys[i]]!}', style: KsTextStyles.price(
                                        color: active ? KsColors.white : KsColors.mainText,
                                        size: 16)),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Custom price input
                      GestureDetector(
                        onTap: _activateCustomPrice,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _useCustomPrice ? KsColors.peach3 : KsColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _useCustomPrice ? KsColors.terracotta : KsColors.peach3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Custom Price',
                                  style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text('₹', style: KsTextStyles.price(color: KsColors.mainText, size: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _customPriceController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onTap: _activateCustomPrice,
                                    onChanged: (_) {
                                      if (_customPriceError != null) {
                                        setState(() => _customPriceError = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter amount',
                                      border: InputBorder.none,
                                      errorText: _customPriceError,
                                    ),
                                    style: KsTextStyles.price(color: KsColors.mainText, size: 18),
                                  ),
                                ),
                                if (_useCustomPrice) ...[
                                  TextButton(
                                    onPressed: _useEnteredPrice,
                                    child: Text('Use this price',
                                        style: KsTextStyles.label(color: KsColors.terracotta, size: 11)),
                                  ),
                                ],
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Save selected band price if no custom price
                            if (!_useCustomPrice && _selectedBand >= 0) {
                              final keys = ['floor', 'recommended', 'ceiling'];
                              final price = prices[keys[_selectedBand]]!;
                              provider.setListedPrice(price);
                            }
                            context.go(AppRoutes.approval);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Review & Verify Listing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KsColors.terracotta,
                            foregroundColor: KsColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _BreakdownRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label,
            style: bold ? KsTextStyles.bodyMedium(size: 12) : KsTextStyles.body(size: 12))),
        Text(value,
            style: bold ? KsTextStyles.price(color: KsColors.terracotta, size: 14)
                : KsTextStyles.bodyMedium(size: 13)),
      ]),
    );
  }
}
