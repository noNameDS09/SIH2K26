import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});
  @override State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  String? _selectedBand;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final listing = session.listing ?? {};
    final prices = listing['prices'] as Map<String, dynamic>? ?? {};
    final floor = (prices['floor']?['value'] ?? 3800) as int;
    final recommended = (prices['recommended']?['value'] ?? 5200) as int;
    final aspirational = (prices['aspirational']?['value'] ?? 7500) as int;

    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: AppBar(
        title: Text('Pricing', style: KsTextStyles.section),
        backgroundColor: KsColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price bands from evidence', style: KsTextStyles.section),
            const SizedBox(height: 8),
            _priceCard('Floor', 'Material cost + labor + overhead', '₹$floor'),
            const SizedBox(height: 8),
            _priceCard('Recommended', 'Market comparable range', '₹$recommended'),
            const SizedBox(height: 8),
            _priceCard('Aspirational', 'GI premium + aspirational value', '₹$aspirational'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/approval'),
                child: const Text('Continue to Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCard(String title, String subtitle, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KsColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
