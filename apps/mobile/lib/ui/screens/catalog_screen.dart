import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _filterIdx = 0;
  static const _filters = ['All', 'Live', 'Pending', 'Draft'];

  static const _listings = [
    ('Handloom Paithani Saree', '₹5,200', 'Live', 'Maheshwar, MP'),
    ('Banjara Embroidery Bag', '₹1,800', 'Pending', 'Kutch, Gujarat'),
    ('Warli Art Painting', '₹3,400', 'Live', 'Palghar, MH'),
    ('Dhokra Metal Figurine', '₹2,600', 'Live', 'Bastar, CG'),
    ('Blue Pottery Vase', '₹1,200', 'Draft', 'Jaipur, RJ'),
    ('Madhubani Wall Art', '₹4,800', 'Live', 'Mithila, Bihar'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filterIdx == 0
        ? _listings
        : _listings.where((l) => l.$3 == _filters[_filterIdx]).toList();

    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'My Catalog'),
          Expanded(
            child: Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final selected = i == _filterIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? KsColors.terracotta : KsColors.surface1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_filters[i],
                                style: KsTextStyles.label(
                                    color: selected ? KsColors.white : KsColors.mainText,
                                    size: 11)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isLive = item.$3 == 'Live';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KsColors.surface1,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: KsColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.image_outlined,
                                  color: KsColors.textSecondary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$1, style: KsTextStyles.bodyMedium(size: 13)),
                                  const SizedBox(height: 2),
                                  Text(item.$4,
                                      style: KsTextStyles.caption.copyWith(
                                          color: KsColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(item.$2,
                                      style: KsTextStyles.price(color: KsColors.terracotta, size: 14)),
                                ],
                              ),
                            ),
                            Column(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? KsColors.paleGreen
                                      : item.$3 == 'Draft'
                                          ? KsColors.surfaceMuted
                                          : KsColors.peach3,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(item.$3,
                                    style: KsTextStyles.label(
                                        color: isLive
                                            ? KsColors.deepGreen
                                            : item.$3 == 'Draft'
                                                ? KsColors.textSecondary
                                                : KsColors.terracotta,
                                        size: 9)),
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          KsBottomNav(
            currentIndex: 2,
            onTap: (i) => _navTap(context, i),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.capture),
        backgroundColor: KsColors.terracotta,
        child: const Icon(Icons.add, color: KsColors.white),
      ),
    );
  }

  void _navTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go(AppRoutes.home); break;
      case 1: context.go(AppRoutes.capture); break;
      case 2: break;
      case 3: context.go(AppRoutes.money); break;
      case 4: context.go(AppRoutes.insights); break;
    }
  }
}
