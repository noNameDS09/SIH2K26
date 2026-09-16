import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/prices.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_stage_progress.dart';
import '../widgets/ks_price_band_card.dart';

/// Stage 3 — dynamic pricing assistant, one of the three mandatory AI
/// capabilities (`01_CONTEXT.md`). Bands come from `POST
/// /v1/listings/{id}/price`, never fabricated client-side — a failed fetch
/// shows a real error with retry, not a fallback number pretending to be
/// a calculation. `13_API.md`: "do not replace with a black box" applies
/// to the client too: no invented margins, no invented breakdown.
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _loading = true;
  bool _failed = false;
  Prices _prices = const Prices();
  String? _selectedKey = 'recommended';
  bool _useCustomPrice = false;
  String? _customPriceError;
  final _customPriceController = TextEditingController();
  bool _breakdownExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrice());
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrice() async {
    final provider = context.read<SessionProvider>();
    final id = provider.listingId ?? (provider.listing?['id'] as String?);
    if (id == null) {
      setState(() { _loading = false; _failed = true; });
      return;
    }
    setState(() { _loading = true; _failed = false; });
    final prices = await ApiService.priceListing(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _prices = prices;
      _failed = !prices.hasBands;
    });
    if (prices.hasBands) {
      final currentListing = provider.listing ?? <String, dynamic>{'id': id};
      provider.updateListing({
        ...currentListing,
        'prices': {
          'floor': prices.floor!.value,
          'recommended': prices.recommended!.value,
          'aspirational': prices.aspirational!.value,
        },
      });
    }
  }

  void _selectBand(String key) => setState(() { _selectedKey = key; _useCustomPrice = false; });

  void _activateCustomPrice() => setState(() { _useCustomPrice = true; _selectedKey = null; });

  void _useEnteredPrice() {
    final price = int.tryParse(_customPriceController.text.trim());
    if (price == null || price <= 0) {
      setState(() => _customPriceError = 'Enter a valid price using numbers only.');
      return;
    }
    context.read<SessionProvider>().setListedPrice(price);
    FocusScope.of(context).unfocus();
    setState(() { _customPriceError = null; _useCustomPrice = true; _selectedKey = null; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹$price will be used on your product card.'),
          behavior: SnackBarBehavior.floating),
    );
  }

  void _continue(SessionProvider provider) {
    if (!_useCustomPrice && _selectedKey != null) {
      final value = switch (_selectedKey) {
        'floor' => _prices.floor?.value,
        'recommended' => _prices.recommended?.value,
        'aspirational' => _prices.aspirational?.value,
        _ => null,
      };
      if (value != null) provider.setListedPrice(value);
    }
    context.go(AppRoutes.approval);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
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
                      const KsStageProgress(stage: 3, label: 'PRICING'),
                      const SizedBox(height: 20),

                      Row(children: [
                        Container(width: 7, height: 7,
                            decoration: const BoxDecoration(color: KsColors.terracotta, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('DYNAMIC PRICING ASSISTANT',
                            style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                      ]),
                      const SizedBox(height: 20),

                      if (_loading) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(color: KsColors.terracotta),
                          ),
                        ),
                      ] else if (_failed) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE4E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD9463A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.error_outline, color: Color(0xFFD9463A), size: 18),
                                SizedBox(width: 8),
                                Text('Could not calculate a price',
                                    style: TextStyle(color: Color(0xFFD9463A), fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                'The pricing server did not respond. Check your connection and try again — we will not show a made-up number.',
                                style: KsTextStyles.body(size: 12),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(onPressed: _fetchPrice, child: const Text('Retry')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Selected price hero
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: KsColors.surface1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: KsColors.peach3),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Recommended', style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
                            const SizedBox(height: 4),
                            Text('₹${_prices.recommended?.value ?? '—'}',
                                style: KsTextStyles.price(color: KsColors.terracotta, size: 28)),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        Text('Select Your Price',
                            style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                        const SizedBox(height: 10),
                        KsPriceBandCard(
                          prices: _prices,
                          selectedKey: _useCustomPrice ? null : _selectedKey,
                          onSelect: _selectBand,
                        ),
                        const SizedBox(height: 12),

                        if (_prices.breakdown.isNotEmpty) ...[
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
                                  Row(children: [
                                    Text('Cost Breakdown', style: KsTextStyles.bodyMedium(size: 13)),
                                    const Spacer(),
                                    Icon(_breakdownExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: KsColors.textSecondary),
                                  ]),
                                  if (_breakdownExpanded) ...[
                                    const SizedBox(height: 12),
                                    for (final entry in _prices.breakdown.entries)
                                      _BreakdownRow(label: entry.key, value: '₹${entry.value}'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

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
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KsColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KsColors.peach3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: KsColors.brown3),
                              const SizedBox(width: 6),
                              Text('Why this range?',
                                  style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              'Floor covers your material and labour cost. Recommended and '
                              'aspirational are calculated from your costing answers and the '
                              'current cluster trend. Tap the ⓘ on any number to see exactly '
                              'where it came from.',
                              style: KsTextStyles.body(size: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_failed || _loading) ? null : () => _continue(provider),
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
  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: KsTextStyles.body(size: 12))),
        Text(value, style: KsTextStyles.bodyMedium(size: 13)),
      ]),
    );
  }
}
