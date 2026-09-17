import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_cards.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  Map<String, dynamic>? _advisorData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService.getAdvisor();
    if (mounted) {
      setState(() {
        _advisorData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(
        title: 'Business Insights',
        onBack: () => context.pop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: KsColors.terracotta),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('See suggestions based on your products and business activity.'),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: KsColors.terracotta))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_advisorData == null || _advisorData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 48, color: KsColors.border),
              const SizedBox(height: 16),
              const Text(
                'Your advisor is quiet for now.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A suggestion appears only when your own records support one. Keep cataloging products!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: KsColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ruleId = _advisorData!['rule_id'] as String? ?? 'insight';
    final sentence = _advisorData!['sentence'] as String? ?? '';
    final listingId = _advisorData!['listing_id'] as String?;

    return RefreshIndicator(
      color: KsColors.terracotta,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Current Focus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: KsColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          KsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: KsColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: KsColors.terracotta,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getInsightTitle(ruleId),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KsColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  sentence,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: KsColors.textSecondary,
                  ),
                ),
                if (listingId != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KsColors.terracotta,
                        foregroundColor: KsColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.push('${AppRoutes.listing}/$listingId');
                      },
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInsightTitle(String ruleId) {
    switch (ruleId) {
      case 'first_publish':
        return 'First Listing Live';
      case 'stale_draft':
        return 'Incomplete Listing';
      case 'underpricing':
        return 'Pricing Opportunity';
      case 'demand_gap':
        return 'Market Demand';
      default:
        return 'Market Insight';
    }
  }
}
