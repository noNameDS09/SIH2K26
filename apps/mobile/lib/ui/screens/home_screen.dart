import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  List<dynamic> _listings = [];
  Map<String, dynamic>? _advisorData;

  String _artisanName = 'Artisan';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  Future<void> _loadData() async {
    try {
      final res = await ApiService.listListings();
      final advisorRes = await ApiService.getAdvisor();

      if (!mounted) return;

      setState(() {
        _listings =
            res['items'] as List<dynamic>? ?? [];

        _advisorData = advisorRes;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('UNAUTHORIZED')) {
        await ApiService.logout();
        if (mounted) context.go(AppRoutes.otp);
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) {
      return 'Date unavailable';
    }

    final dt = DateTime.tryParse(dateStr);

    if (dt == null) {
      return 'Date unavailable';
    }

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getTitle(dynamic item) {
    return item['title_en'] ??
        item['title_hi'] ??
        item['title'] ??
        'Untitled';
  }

  String _getPrice(dynamic item) {
    final price =
        item['prices']?['listed']?['value'] ??
        item['price_hint'];

    if (price == null) {
      return 'Price not set';
    }

    return '₹$price';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final drafts = _listings
        .where(
          (e) => e['status'] != 'published',
        )
        .toList();

    final published = _listings
        .where(
          (e) => e['status'] == 'published',
        )
        .toList();

    final recent = List<dynamic>.from(_listings)
      ..sort(
        (a, b) => (b['updatedAt'] ?? '')
            .toString()
            .compareTo(
              (a['updatedAt'] ?? '').toString(),
            ),
      );

    return Scaffold(
      backgroundColor: KsColors.background,

      appBar: KsAppHeader(
        title: 'My Workspace',
        onBack: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: KsColors.terracotta),
            onPressed: () async {
              await ApiService.logout();
              if (mounted) context.go(AppRoutes.otp);
            },
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: KsColors.terracotta,
              ),
            )
          : RefreshIndicator(
              color: KsColors.terracotta,
              backgroundColor: KsColors.surface,
              onRefresh: _loadData,

              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      110,
                    ),

                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildWelcomeSection(),

                          const SizedBox(height: 20),

                          _buildQuickActions(),

                          const SizedBox(height: 26),

                          _buildCatalogOverview(
                            published.length,
                            drafts.length,
                          ),

                          const SizedBox(height: 26),

                          _buildAdvisorSection(),

                          const SizedBox(height: 26),

                          _buildRecentHeader(),

                          const SizedBox(height: 12),

                          if (recent.isEmpty)
                            _buildEmptyState()
                          else
                            ...recent.take(3).map(
                              (item) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child:
                                    _buildRecentListing(
                                  item,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: KsBottomNav(
        currentIndex: 0,

        onTap: (index) {
          if (index == 0) return;

          if (index == 1) {
            context.go(AppRoutes.capture);
          } else if (index == 2) {
            context.go(AppRoutes.samuh);
          } else if (index == 3) {
            context.go(AppRoutes.shop);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Not part of this build.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ===========================================================================
  // WELCOME
  // ===========================================================================

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        17,
      ),

      decoration: BoxDecoration(
        color: KsColors.terracottaSoft,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: KsColors.peach1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,

                          decoration:
                              const BoxDecoration(
                            color: KsColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 7),

                        const Text(
                          'YOUR WORKSPACE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color:
                                KsColors.terracotta,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Namaste,',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KsColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 1),

                    Text(
                      _artisanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        color: KsColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Your craft. Your catalog. Your story.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: KsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: KsColors.surface,
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                padding: const EdgeInsets.all(8),

                child: Image.asset(
                  'assets/images/kalasetu_logo.png',
                  fit: BoxFit.contain,

                  errorBuilder:
                      (_, __, ___) {
                    return const Icon(
                      Icons.auto_awesome_rounded,
                      color: KsColors.terracotta,
                      size: 24,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Decorative craft illustration.
          SizedBox(
            width: double.infinity,
            height: 92,

            child: Image.asset(
              'assets/images/KS-Hero-transparent.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,

              errorBuilder: (_, __, ___) {
                return const SizedBox.shrink();
              },
            ),
          ),

          const SizedBox(height: 7),

          // Primary action.
          SizedBox(
            width: double.infinity,
            height: 52,

            child: FilledButton(
              onPressed: () {
                context.go(AppRoutes.capture);
              },

              style: FilledButton.styleFrom(
                backgroundColor:
                    KsColors.terracotta,

                foregroundColor:
                    KsColors.white,

                elevation: 0,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,

                    decoration: BoxDecoration(
                      color: KsColors.white
                          .withValues(
                        alpha: .16,
                      ),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 17,
                      color: KsColors.white,
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Add new product',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 1),

                        Text(
                          'Create a listing from a product photo',
                          style: TextStyle(
                            fontSize: 9.5,
                            color:
                                KsColors.terracottaSoft,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUICK ACTIONS
  // ===========================================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: KsColors.ink,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Get to your most-used tools faster.',
          style: TextStyle(
            fontSize: 11,
            color: KsColors.textSecondary,
          ),
        ),

        const SizedBox(height: 13),

        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.add_box_outlined,
                title: 'Add product',
                subtitle: 'New listing',
                color: KsColors.terracotta,
                onTap: () {
                  context.go(
                    AppRoutes.capture,
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildQuickAction(
                icon: Icons.edit_note_rounded,
                title: 'Drafts',
                subtitle: '${_draftCount()} saved',
                color: KsColors.orange,
                onTap: () {
                  context.go(
                    AppRoutes.shop,
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.insights_outlined,
                title: 'Insights',
                subtitle: 'Business tips',
                color: KsColors.green,
                onTap: () {
                  context.push(
                    AppRoutes.advisor,
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildQuickAction(
                icon: Icons.inventory_2_outlined,
                title: 'Catalog',
                subtitle: '${_listings.length} items',
                color: KsColors.deepGreen,
                onTap: () {
                  context.go(
                    AppRoutes.shop,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _draftCount() {
    return _listings
        .where(
          (e) => e['status'] != 'published',
        )
        .length;
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: KsColors.surface,

      borderRadius: BorderRadius.circular(17),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(17),

        child: Container(
          constraints:
              const BoxConstraints(
            minHeight: 84,
          ),

          padding:
              const EdgeInsets.all(12),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(17),

            border: Border.all(
              color: KsColors.border,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color:
                      color.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Icon(
                  icon,
                  size: 19,
                  color: color,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            KsColors.ink,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 9.5,
                        color:
                            KsColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: KsColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CATALOG OVERVIEW
  // ===========================================================================

  Widget _buildCatalogOverview(
    int published,
    int drafts,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'Your catalog',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color: KsColors.ink,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'A snapshot of your current listings',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          KsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Material(
              color: Colors.transparent,

              child: InkWell(
                onTap: () {
                  context.go(
                    AppRoutes.shop,
                  );
                },

                borderRadius:
                    BorderRadius.circular(20),

                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),

                  child: Row(
                    children: [
                      Text(
                        'View catalog',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              KsColors.terracotta,
                        ),
                      ),

                      SizedBox(width: 3),

                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color:
                            KsColors.terracotta,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 10,
          ),

          decoration: BoxDecoration(
            color: KsColors.surface,

            borderRadius:
                BorderRadius.circular(19),

            border: Border.all(
              color: KsColors.border,
            ),
          ),

          child: Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  icon:
                      Icons.check_circle_outline_rounded,
                  value:
                      published.toString(),
                  label: 'Published',
                  color: KsColors.green,
                ),
              ),

              _buildVerticalDivider(),

              Expanded(
                child: _buildOverviewMetric(
                  icon:
                      Icons.edit_note_rounded,
                  value:
                      drafts.toString(),
                  label: 'Drafts',
                  color: KsColors.orange,
                ),
              ),

              _buildVerticalDivider(),

              Expanded(
                child: _buildOverviewMetric(
                  icon:
                      Icons.inventory_2_outlined,
                  value:
                      _listings.length.toString(),
                  label: 'Total',
                  color:
                      KsColors.terracotta,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,

          decoration: BoxDecoration(
            color:
                color.withValues(
              alpha: .10,
            ),
            borderRadius:
                BorderRadius.circular(11),
          ),

          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          value,

          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: KsColors.ink,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,

          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: KsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 62,
      width: 1,
      color: KsColors.border,
    );
  }

  // ===========================================================================
  // BUSINESS INSIGHTS
  // ===========================================================================

  Widget _buildAdvisorSection() {
    final hasInsight =
        _advisorData != null &&
        _advisorData!.isNotEmpty;

    final message = hasInsight
        ? (_advisorData!['sentence']
                as String? ??
            'You have a new business insight waiting.')
        : 'See suggestions based on your products and business activity.';

    return Material(
      color: Colors.transparent,

      borderRadius: BorderRadius.circular(19),

      child: InkWell(
        onTap: () {
          context.push(
            AppRoutes.advisor,
          );
        },

        borderRadius:
            BorderRadius.circular(19),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: KsColors.surfaceWarm,

            borderRadius:
                BorderRadius.circular(19),

            border: Border.all(
              color: KsColors.border,
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: KsColors.surface,
                  borderRadius:
                      BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: KsColors.terracotta,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Text(
                          'BUSINESS INSIGHT',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: 1,
                            color:
                                KsColors.terracotta,
                          ),
                        ),

                        if (hasInsight) ...[
                          const SizedBox(width: 6),

                          Container(
                            width: 5,
                            height: 5,

                            decoration:
                                const BoxDecoration(
                              color:
                                  KsColors.green,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      message,

                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color:
                            KsColors.ink,
                      ),
                    ),

                    const SizedBox(height: 9),

                    const Row(
                      children: [
                        Text(
                          'View insights',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                KsColors.terracotta,
                          ),
                        ),

                        SizedBox(width: 4),

                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color:
                              KsColors.terracotta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // RECENT WORK
  // ===========================================================================

  Widget _buildRecentHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: KsColors.textMuted,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Recent work',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: KsColors.ink,
                ),
              ),
            ],
          ),
        ),

        Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: () {
              context.go(
                AppRoutes.shop,
              );
            },

            borderRadius:
                BorderRadius.circular(20),

            child: const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),

              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color:
                      KsColors.terracotta,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // RECENT LISTING
  // ===========================================================================

  Widget _buildRecentListing(
    dynamic item,
  ) {
    final isPublished =
        item['status'] == 'published';

    final title = _getTitle(item);

    final price = _getPrice(item);

    final date =
        _formatDate(item['updatedAt']);

    return Material(
      color: KsColors.surface,

      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        onTap: () {
          if (isPublished) {
            context.push(
              '${AppRoutes.listing}/${item['id']}',
            );
          } else {
            final sp =
                context.read<SessionProvider>();

            sp.listingId = item['id'];

            context.go(
              AppRoutes.intelligence,
            );
          }
        },

        borderRadius:
            BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(11),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color: KsColors.border,
            ),
          ),

          child: Row(
            children: [
              _buildProductImage(
                item,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration: BoxDecoration(
                            color: isPublished
                                ? KsColors
                                    .greenSoft
                                : KsColors
                                    .surfaceMuted,

                            borderRadius:
                                BorderRadius.circular(
                              7,
                            ),
                          ),

                          child: Text(
                            isPublished
                                ? 'PUBLISHED'
                                : 'DRAFT',

                            style: TextStyle(
                              fontSize: 8,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: .4,
                              color: isPublished
                                  ? KsColors
                                      .greenDark
                                  : KsColors
                                      .textSecondary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Icon(
                          isPublished
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .edit_outlined,

                          size: 16,

                          color:
                              KsColors.textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      title,

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w800,
                        color: KsColors.ink,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Text(
                          price,

                          style:
                              const TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                KsColors.terracotta,
                          ),
                        ),

                        const SizedBox(width: 6),

                        const Text(
                          '•',
                          style: TextStyle(
                            color:
                                KsColors.textMuted,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            date,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 9.5,
                              color: KsColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: KsColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(
    dynamic item,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),

      child: Container(
        width: 78,
        height: 78,

        color: KsColors.surfaceMuted,

        child: Image.network(
          '${ApiService.baseUrl}/v1/listings/'
          '${item['id']}/media/studio.jpg',

          headers:
              ApiService.authHeaders,

          fit: BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Center(
              child: Icon(
                Icons
                    .image_outlined,
                size: 26,
                color:
                    KsColors.textMuted,
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        25,
      ),

      decoration: BoxDecoration(
        color: KsColors.surface,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: KsColors.border,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,

            decoration:
                const BoxDecoration(
              color:
                  KsColors.terracottaSoft,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.inventory_2_outlined,
              size: 27,
              color:
                  KsColors.terracotta,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Start your catalog',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: KsColors.ink,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Add your first product and let KalaSetu '
            'help you turn your craft into a beautiful listing.',
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: KsColors.textSecondary,
            ),
          ),

          const SizedBox(height: 17),

          SizedBox(
            height: 44,

            child: FilledButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.capture,
                );
              },

              style: FilledButton.styleFrom(
                backgroundColor:
                    KsColors.terracotta,

                foregroundColor:
                    KsColors.white,

                elevation: 0,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),

              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),

              label: const Text(
                'Add first product',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}