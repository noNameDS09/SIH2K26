import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'KalaSetu'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Welcome banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KsColors.terracotta, Color(0xFFD4682A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Namaste!', style: KsTextStyles.h2.copyWith(color: KsColors.white)),
                        const SizedBox(height: 4),
                        Text('Your crafts are live across India',
                            style: KsTextStyles.body(color: KsColors.white.withAlpha(200), size: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  Text('Quick Actions',
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickAction(
                      icon: Icons.add_a_photo_outlined,
                      label: 'Add Product',
                      onTap: () => context.go(AppRoutes.capture),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(
                      icon: Icons.grid_view_rounded,
                      label: 'My Catalog',
                      onTap: () => context.go(AppRoutes.shop),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(
                      icon: Icons.currency_rupee,
                      label: 'Earnings',
                      onTap: () => context.go(AppRoutes.money),
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // Stats row
                  Text('Today\'s Overview',
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StatTile(label: 'Products', value: '12')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(label: 'Orders', value: '3')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(label: 'Revenue', value: '₹4.2k')),
                  ]),
                  const SizedBox(height: 24),

                  // Recent listings placeholder
                  Text('Recent Listings',
                      style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                  const SizedBox(height: 12),
                  ...List.generate(3, (i) => _RecentListingTile(index: i)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          KsBottomNav(
            currentIndex: 0,
            onTap: (i) => _navTap(context, i),
          ),
        ],
      ),
    );
  }

  void _navTap(BuildContext context, int i) {
    switch (i) {
      case 0: break; // already here
      case 1: context.go(AppRoutes.capture); break;
      case 2: context.go(AppRoutes.shop); break;
      case 3: context.go(AppRoutes.money); break;
      case 4: context.go(AppRoutes.insights); break;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: KsColors.surface1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: KsColors.terracotta, size: 24),
            const SizedBox(height: 6),
            Text(label, style: KsTextStyles.label(color: KsColors.mainText, size: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: KsTextStyles.price(color: KsColors.terracotta, size: 20)),
          const SizedBox(height: 4),
          Text(label, style: KsTextStyles.label(color: KsColors.textSecondary, size: 9)),
        ],
      ),
    );
  }
}

class _RecentListingTile extends StatelessWidget {
  final int index;
  const _RecentListingTile({required this.index});

  static const _titles = ['Handloom Paithani Saree', 'Banjara Embroidery Bag', 'Warli Art Painting'];
  static const _prices = ['₹5,200', '₹1,800', '₹3,400'];
  static const _statuses = ['Live', 'Pending', 'Live'];

  @override
  Widget build(BuildContext context) {
    final isLive = _statuses[index] == 'Live';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KsColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined, color: KsColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[index], style: KsTextStyles.bodyMedium(size: 13)),
                const SizedBox(height: 2),
                Text(_prices[index], style: KsTextStyles.price(color: KsColors.terracotta, size: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isLive ? KsColors.paleGreen : KsColors.peach3,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_statuses[index],
                style: KsTextStyles.label(
                    color: isLive ? KsColors.deepGreen : KsColors.terracotta, size: 9)),
          ),
        ],
      ),
    );
  }
}
