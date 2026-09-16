import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/listing.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_listing_card.dart';
import '../widgets/ks_spoken_empty_state.dart';

/// Stage 5–6 — inventory. `GET /v1/listings`, not the hardcoded six-item
/// list this screen used to show. Tapping a draft resumes it at the
/// furthest-along pipeline step it reached; tapping a published listing
/// shows its own details only — never a market/browse surface (spec: no
/// shop, no browse-all, no cart on the app).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _filterIdx = 0;
  static const _filters = ['All', 'Published', 'Draft'];

  bool _loading = true;
  List<Listing> _listings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final listings = await ApiService.listListings();
    if (!mounted) return;
    setState(() { _listings = listings; _loading = false; });
  }

  String _resumeRoute(Listing l) {
    if (l.originalUrl == null) return AppRoutes.capture;
    if (l.titleEn == null && l.titleHi == null) return AppRoutes.live;
    if (l.missingCostingSlots.isNotEmpty) return AppRoutes.intelligence;
    return AppRoutes.pricing;
  }

  void _openDraft(SessionProvider provider, Listing l) {
    provider.listingId = l.id;
    provider.updateListing(l.toJson());
    context.go(_resumeRoute(l));
  }

  void _openPublished(Listing l) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.titleEn ?? l.titleHi ?? 'Listing', style: KsTextStyles.h3),
            const SizedBox(height: 8),
            if (l.prices.listed != null)
              Text('₹${l.prices.listed}', style: KsTextStyles.price(color: KsColors.terracotta, size: 20)),
            if (l.publicUrl != null) ...[
              const SizedBox(height: 8),
              Text(l.publicUrl!, style: KsTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final filtered = switch (_filterIdx) {
      1 => _listings.where((l) => l.status == ListingStatus.published).toList(),
      2 => _listings.where((l) => l.status == ListingStatus.draft).toList(),
      _ => _listings,
    };

    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'My Catalog'),
          Expanded(
            child: Column(
              children: [
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: KsColors.terracotta))
                      : filtered.isEmpty
                          ? const KsSpokenEmptyState(
                              icon: Icons.inventory_2_outlined,
                              text: 'No listings yet — tap + to make your first one.',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final l = filtered[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: KsListingCard(
                                      listing: l,
                                      onTap: () => l.status == ListingStatus.published
                                          ? _openPublished(l)
                                          : _openDraft(provider, l),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          KsBottomNav(
            currentIndex: 2,
            onTap: (i) => KsBottomNav.navigate(context, i),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          provider.reset();
          context.go(AppRoutes.capture);
        },
        backgroundColor: KsColors.terracotta,
        child: const Icon(Icons.add, color: KsColors.white),
      ),
    );
  }
}
