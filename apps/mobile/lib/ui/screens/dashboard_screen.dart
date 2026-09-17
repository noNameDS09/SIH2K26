import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';
import '../widgets/ks_cards.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  List<dynamic> _items = [];

  String _status = 'all';
  String _sort = 'updated';
  String _query = '';

  String? _advisorSentence;

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
      final insightsRes = await ApiService.getInsights();

      if (!mounted) return;

      setState(() {
        _items = res['items'] as List<dynamic>? ?? [];

        final advisor =
            insightsRes['advisor'] as Map<String, dynamic>?;

        if (advisor != null &&
            advisor['sentence'] != null &&
            advisor['sentence'].toString().isNotEmpty) {
          _advisorSentence = advisor['sentence'].toString();
        }

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
    if (dateStr == null) return 'Date unavailable';

    final dt = DateTime.tryParse(dateStr);

    if (dt == null) return 'Date unavailable';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  int _getPrice(dynamic item) {
    final priceValue =
        item['prices']?['listed']?['value'] ??
        item['price_hint'];

    if (priceValue is num) {
      return priceValue.toInt();
    }

    return 0;
  }

  String _getTitle(dynamic item) {
    return item['title_en'] ??
        item['title_hi'] ??
        item['title'] ??
        'Untitled';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final visible = _getVisibleItems();

    return Scaffold(
      backgroundColor: KsColors.background,

      appBar: KsAppHeader(
        title: 'My Catalog',
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
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      110,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildPageIntro(),

                          const SizedBox(height: 18),

                          _buildIntelligenceCards(),

                          const SizedBox(height: 20),

                          _buildCatalogSummary(),

                          const SizedBox(height: 18),

                          _buildFilters(),

                          const SizedBox(height: 20),

                          _buildCatalogHeader(visible.length),

                          const SizedBox(height: 12),

                          if (visible.isEmpty)
                            _buildEmptyState()
                          else
                            ...visible.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: _buildListingCard(item),
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
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;

          if (index == 0) {
            context.go(AppRoutes.home);
          } else if (index == 1) {
            context.go(AppRoutes.capture);
          } else if (index == 2) {
            context.go(AppRoutes.samuh);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not part of this build.'),
              ),
            );
          }
        },
      ),
    );
  }

  // ===========================================================================
  // FILTERING / SORTING
  // ===========================================================================

  List<dynamic> _getVisibleItems() {
    final query = _query.trim().toLowerCase();

    final visible = _items.where((item) {
      final status = item['status'] ?? 'draft';

      if (_status != 'all' && status != _status) {
        return false;
      }

      if (query.isNotEmpty) {
        final title = _getTitle(item).toLowerCase();

        final craft = (
          item['fields']?['craft'] ??
          item['craft'] ??
          ''
        ).toString().toLowerCase();

        if (!title.contains(query) && !craft.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    visible.sort((a, b) {
      if (_sort == 'title') {
        return _getTitle(a).compareTo(_getTitle(b));
      }

      if (_sort == 'price') {
        return _getPrice(b).compareTo(_getPrice(a));
      }

      return (b['updatedAt'] ?? '')
          .toString()
          .compareTo(
            (a['updatedAt'] ?? '').toString(),
          );
    });

    return visible;
  }

  // ===========================================================================
  // PAGE INTRO
  // ===========================================================================

  Widget _buildPageIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Catalog',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: KsColors.ink,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Manage your products and continue your work.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: KsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: () => context.go(AppRoutes.capture),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KsColors.terracotta,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: KsColors.white,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ADVISOR
  // ===========================================================================

  Widget _buildIntelligenceCards() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.advisor),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KsColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KsColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KsColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: KsColors.terracotta,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KsColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Understand your business performance and improve it.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: KsColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: KsColors.terracotta,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => context.push('/trends'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KsColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KsColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KsColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: KsColors.terracotta,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KsColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Discover trends relevant to your craft and products.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: KsColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: KsColors.terracotta,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Widget _buildCatalogSummary() {
    final total = _items.length;

    final drafts = _items.where(
      (e) => (e['status'] ?? 'draft') == 'draft',
    ).length;

    final published = _items.where(
      (e) => e['status'] == 'published',
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            icon: Icons.inventory_2_outlined,
            value: total.toString(),
            label: 'Total',
            color: KsColors.terracotta,
          ),

          _buildSummaryDivider(),

          _buildSummaryItem(
            icon: Icons.edit_note_rounded,
            value: drafts.toString(),
            label: 'Drafts',
            color: KsColors.orange,
          ),

          _buildSummaryDivider(),

          _buildSummaryItem(
            icon: Icons.check_circle_outline_rounded,
            value: published.toString(),
            label: 'Published',
            color: KsColors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),

          const SizedBox(width: 9),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KsColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: KsColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      color: KsColors.border,
    );
  }

  // ===========================================================================
  // FILTERS
  // ===========================================================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildTab(
                'all',
                'All',
                _items.length,
              ),
              const SizedBox(width: 7),
              _buildTab(
                'draft',
                'Drafts',
                _items.where(
                  (e) =>
                      (e['status'] ?? 'draft') == 'draft',
                ).length,
              ),
              const SizedBox(width: 7),
              _buildTab(
                'published',
                'Published',
                _items.where(
                  (e) => e['status'] == 'published',
                ).length,
              ),
            ],
          ),

          const SizedBox(height: 11),

          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    color: KsColors.ink,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: KsColors.textSecondary,
                    ),
                    hintText: 'Search your catalog',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: KsColors.textMuted,
                    ),
                    filled: true,
                    fillColor: KsColors.background,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: KsColors.terracotta,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _buildSortButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      initialValue: _sort,
      onSelected: (value) {
        setState(() {
          _sort = value;
        });
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'updated',
          child: Text('Recently updated'),
        ),
        PopupMenuItem(
          value: 'title',
          child: Text('Title'),
        ),
        PopupMenuItem(
          value: 'price',
          child: Text('Price'),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: KsColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 20,
          color: KsColors.textSecondary,
        ),
      ),
    );
  }

  // ===========================================================================
  // CATALOG HEADER
  // ===========================================================================

  Widget _buildCatalogHeader(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your products',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KsColors.ink,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: KsColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count ${count == 1 ? 'item' : 'items'}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: KsColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LISTING CARD
  // ===========================================================================

  Widget _buildListingCard(dynamic item) {
    final isPublished = item['status'] == 'published';

    final title = _getTitle(item);
    final price = _getPrice(item);

    final priceStr =
        price > 0 ? '₹$price' : 'Price not set';

    final dateStr =
        _formatDate(item['updatedAt']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(item),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KsPill(
                          text: isPublished
                              ? 'Published'
                              : 'Draft',
                          green: isPublished,
                        ),

                        const Spacer(),

                        const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: KsColors.textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: KsColors.ink,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      priceStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPublished
                            ? KsColors.greenDark
                            : KsColors.terracotta,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.update_rounded,
                          size: 12,
                          color: KsColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: KsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildListingAction(
            isPublished: isPublished,
            item: item,
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(dynamic item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        height: 105,
        color: KsColors.surfaceMuted,
        child: Image.network(
          '${ApiService.baseUrl}/v1/listings/'
          '${item['id']}/media/studio.jpg',
          headers: ApiService.authHeaders,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: KsColors.textMuted,
                  size: 28,
                ),
                SizedBox(height: 4),
                Text(
                  'No image',
                  style: TextStyle(
                    fontSize: 9,
                    color: KsColors.textMuted,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListingAction({
    required bool isPublished,
    required dynamic item,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: isPublished
              ? KsColors.surfaceWarm
              : KsColors.terracotta,
          foregroundColor: isPublished
              ? KsColors.terracotta
              : KsColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
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
        icon: Icon(
          isPublished
              ? Icons.visibility_outlined
              : Icons.edit_outlined,
          size: 17,
        ),
        label: Text(
          isPublished
              ? 'View product'
              : 'Continue editing',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    final hasItems = _items.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        32,
        24,
        28,
      ),
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: KsColors.terracottaSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 29,
              color: KsColors.terracotta,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            hasItems
                ? 'No matching products'
                : 'Your catalog is empty',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KsColors.ink,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            hasItems
                ? 'Try another search or choose a different status.'
                : 'Add your first product and start building your catalog.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: KsColors.textSecondary,
            ),
          ),

          if (!hasItems) ...[
            const SizedBox(height: 18),

            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: () {
                  context.go(AppRoutes.capture);
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      KsColors.terracotta,
                  foregroundColor: KsColors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Add product',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // STATUS TAB
  // ===========================================================================

  Widget _buildTab(
    String key,
    String label,
    int count,
  ) {
    final active = _status == key;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _status = key;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: active
                ? KsColors.terracottaSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: active
                      ? KsColors.terracotta
                      : KsColors.textSecondary,
                ),
              ),

              const SizedBox(width: 5),

              Container(
                constraints:
                    const BoxConstraints(minWidth: 18),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? KsColors.terracotta
                      : KsColors.surfaceMuted,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: active
                        ? KsColors.white
                        : KsColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}