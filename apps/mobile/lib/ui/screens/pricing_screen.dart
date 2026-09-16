import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  String _error = '';
  String _message = '';
  String _customPrice = '';
  bool _useCustom = false;
  String _selected = 'recommended';
  Map<String, dynamic>? _listing;
  Map<String, dynamic> _prices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<SessionProvider>();
    final id = provider.listingId;
    if (id == null || id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final listingRes = await ApiService.getListing(id);
      final priceRes = await ApiService.getPrice(id);
      setState(() {
        _listing = listingRes;
        _prices = priceRes['prices'] as Map<String, dynamic>? ?? {};
        _loading = false;
        final existing = (listingRes['price_hint'] as num?)?.toInt();
        if (existing != null) _customPrice = existing.toString();
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrice() async {
    if (_listing == null || _saving) return;
    final valueStr = _useCustom ? _customPrice : (_prices[_selected]?['value']?.toString() ?? '');
    final value = int.tryParse(valueStr);
    if (value == null || value <= 0) {
      setState(() => _error = 'Choose a calculated price or enter a valid custom price.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.patchListing(_listing!['id'] as String, {'price_hint': value});
      if (!mounted) return;
      setState(() {
        _saved = true;
        _message = 'Price saved';
        _saving = false;
        _error = '';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save price');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatMoney(int? value) => value != null ? '₹${value.toStringAsFixed(0)}' : '--';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STAGE 5 — PRICING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9F3C07))),
              const SizedBox(height: 16),
              const Text('Choose a fair price', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('KalaSetu calculates a transparent range.'),
              const SizedBox(height: 24),
              ...[
                {'key': 'floor', 'title': 'Minimum sustainable'},
                {'key': 'recommended', 'title': 'Recommended'},
                {'key': 'aspirational', 'title': 'Higher opportunity'},
              ].map((band) {
                final price = _prices[band['key']]?['value'] as int?;
                final isSelected = !_useCustom && _selected == band['key'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFEF8F4) : Colors.white,
                    border: Border.all(color: isSelected ? const Color(0xFF9F3C07) : const Color(0xFFE7E1DD)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(band['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(price != null ? '₹${price.toStringAsFixed(0)}' : 'Not calculated', style: const TextStyle(fontSize: 11, color: Color(0xFF705F58))),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => setState(() => _selected = band['key'] as String),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text('Custom amount', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount in INR'),
                controller: TextEditingController(text: _customPrice)..selection = TextSelection.collapsed(offset: _customPrice.length)..addListener(() { setState(() => _useCustom = true); }),
                onChanged: (v) => setState(() => _customPrice = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _savePrice,
                  child: Text(_saving ? 'Saving...' : 'Save price'),
                ),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_message, style: const TextStyle(color: Color(0xFF476430), fontSize: 12)),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.go('/intelligence'), child: const Text('Edit details'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: (!_saved) ? null : () => context.go('/approval'),
                      child: const Text('Continue to approval'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
