import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/advisor_line.dart';
import '../../models/listing.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_advisor_line.dart';
import '../widgets/ks_listing_card.dart';

/// Stage 6 — home. "Home speaks one true line or silence" (`11_APP_PLAN.md`
/// Step 7 working-if). Everything below the banner is real data from
/// `GET /v1/advisor` and `GET /v1/listings`, not the fixed
/// Products=12/Orders=3/Revenue=₹4.2k this screen used to show forever.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  AdvisorLine? _advisor;
  List<Listing> _recent = [];
  bool _spokenOnce = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.advisor(),
      ApiService.listListings(limit: 3),
    ]);
    if (!mounted) return;
    setState(() {
      _advisor = results[0] as AdvisorLine?;
      _recent = results[1] as List<Listing>;
      _loading = false;
    });
    final provider = context.read<SessionProvider>();
    if (!_spokenOnce && _advisor != null && provider.speakScreensEnabled) {
      _spokenOnce = true;
      provider.speakText(_advisor!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final published = _recent.where((l) => l.status == ListingStatus.published).length;

    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'KalaSetu'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Welcome banner — no longer claims listings are "live
                    // across India" regardless of whether any exist.
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
                          Text(
                            published > 0
                                ? 'You have $published published listing${published == 1 ? '' : 's'}'
                                : 'Ready to list your first product',
                            style: KsTextStyles.body(color: KsColors.white.withAlpha(200), size: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_loading) KsAdvisorLine(
                      line: _advisor,
                      onSpeak: _advisor == null
                          ? null
                          : () => context.read<SessionProvider>().speakText(_advisor!.text),
                    ),
                    if (!_loading && _advisor != null) const SizedBox(height: 16),

                    Text('Quick Actions',
                        style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _QuickAction(
                        icon: Icons.add_a_photo_outlined,
                        label: 'Add Product',
                        onTap: () {
                          context.read<SessionProvider>().reset();
                          context.go(AppRoutes.capture);
                        },
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

                    Text('Recent Listings',
                        style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: KsColors.terracotta),
                      ))
                    else if (_recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nothing here yet.',
                            style: KsTextStyles.body(color: KsColors.textSecondary, size: 13)),
                      )
                    else
                      ..._recent.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: KsListingCard(
                              listing: l,
                              onTap: () => context.go(AppRoutes.shop),
                            ),
                          )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          KsBottomNav(
            currentIndex: 0,
            onTap: (i) => KsBottomNav.navigate(context, i),
          ),
        ],
      ),
    );
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
