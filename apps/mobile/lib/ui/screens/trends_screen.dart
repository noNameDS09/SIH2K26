import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_cards.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  Map<String, dynamic>? _trendsData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService.getTrends();
    if (mounted) {
      setState(() {
        _trendsData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(
        title: 'Trend Analysis',
        onBack: () => context.pop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: KsColors.terracotta),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('See market trends based on current sales and listings.'),
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
    if (_trendsData == null || _trendsData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded, size: 48, color: KsColors.border),
              const SizedBox(height: 16),
              const Text(
                'No trends available yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later when more data is collected from the market.',
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

    final topCraft = _trendsData!['craft'] as String? ?? 'Various Crafts';
    final cluster = _trendsData!['cluster'] as String? ?? 'Multiple Clusters';
    final risingList = (_trendsData!['rising'] as List<dynamic>?) ?? [];
    
    // Capitalize first letters
    String capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
    final displayCraft = capitalize(topCraft);
    final displayCluster = capitalize(cluster);
    final rising = risingList.map((e) => capitalize(e.toString())).toList();

    return RefreshIndicator(
      color: KsColors.terracotta,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Market Overview',
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
                _buildTrendRow(
                  icon: Icons.category_rounded,
                  title: 'Top Craft',
                  value: displayCraft,
                ),
                const Divider(height: 32, color: KsColors.border),
                _buildTrendRow(
                  icon: Icons.location_on_rounded,
                  title: 'Top Cluster',
                  value: displayCluster,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (rising.isNotEmpty) ...[
            const Text(
              'Rising Demand',
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
                  const Text(
                    'What buyers are looking for right now:',
                    style: TextStyle(
                      fontSize: 14,
                      color: KsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rising.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: KsColors.greenSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KsColors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded, size: 16, color: KsColors.greenDark),
                            const SizedBox(width: 6),
                            Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: KsColors.greenDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTrendRow({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: KsColors.surfaceWarm,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: KsColors.terracotta,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: KsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KsColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
