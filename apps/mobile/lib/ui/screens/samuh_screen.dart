import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_bottom_nav.dart';

class SamuhScreen extends StatefulWidget {
  const SamuhScreen({super.key});

  @override
  State<SamuhScreen> createState() => _SamuhScreenState();
}

class _SamuhScreenState extends State<SamuhScreen> {
  int _selectedFilter = 0;

  final List<String> _filters = [
    'For You',
    'Artisans',
    'Announcements',
    'Nearby',
  ];

  // ---------------------------------------------------------------------------
  // REMOTE IMAGES
  // ---------------------------------------------------------------------------

  static const String _featuredImage =
      'https://images.unsplash.com/photo-1775669954911-fc68d9deae84'
      '?auto=format&fit=crop&w=1200&q=85';

  static const String _weavingImage =
      'https://images.unsplash.com/photo-1773739967506-2c858c8bde3c'
      '?auto=format&fit=crop&w=1000&q=85';

  static const String _textileImage =
      'https://images.unsplash.com/photo-1775669954897-8ed90ca9f0fa'
      '?auto=format&fit=crop&w=1000&q=85';

  // A secondary craft image.
  static const String _craftImage =
      'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d'
      '?auto=format&fit=crop&w=1000&q=85';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,

      appBar: KsAppHeader(
        title: 'Samuh',
        onBack: null,
      ),

      body: RefreshIndicator(
        color: KsColors.terracotta,
        backgroundColor: KsColors.surface,
        onRefresh: () async {
          await Future.delayed(
            const Duration(milliseconds: 700),
          );
        },

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
                    _buildCommunityHeader(),

                    const SizedBox(height: 18),

                    _buildFilterBar(),

                    const SizedBox(height: 18),

                    _buildCreatePostCard(),

                    const SizedBox(height: 26),

                    _buildSectionHeader(),

                    const SizedBox(height: 14),

                    _buildFeaturedAnnouncement(),

                    const SizedBox(height: 14),

                    _buildArtisanPost(
                      author: 'Ramesh Weaver',
                      location: 'Chanderi, Madhya Pradesh',
                      time: '5h',
                      initials: 'RW',
                      avatarColor: KsColors.terracottaSoft,
                      imageUrl: _weavingImage,
                      content:
                          'Just finished this new batch of Chanderi Silk warp. '
                          'The KalaSetu AI helped me write a beautiful provenance '
                          'story for this piece.',
                      likes: 45,
                      comments: 4,
                      category: 'Weaving',
                    ),

                    const SizedBox(height: 14),

                    _buildArtisanPost(
                      author: 'Sita Devi',
                      location: 'Bagh, Madhya Pradesh',
                      time: '1d',
                      initials: 'SD',
                      avatarColor: KsColors.greenSoft,
                      imageUrl: _textileImage,
                      content:
                          'The natural dyes came out perfectly vibrant this season. '
                          'Connecting with buyers directly through the app has helped '
                          'improve my margins.',
                      likes: 89,
                      comments: 12,
                      category: 'Natural Dyes',
                    ),

                    const SizedBox(height: 14),

                    _buildArtisanPost(
                      author: 'KalaSetu Artisan',
                      location: 'Jaipur, Rajasthan',
                      time: '2d',
                      initials: 'KA',
                      avatarColor: KsColors.surfaceMuted,
                      imageUrl: _craftImage,
                      content:
                          'Sharing a glimpse of our latest handcrafted collection. '
                          'Every piece carries the story of the artisan who created it.',
                      likes: 67,
                      comments: 8,
                      category: 'Craft Story',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: KsBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;

          if (index == 0) {
            context.go(AppRoutes.home);
          } else if (index == 1) {
            context.go(AppRoutes.capture);
          } else if (index == 3) {
            context.go(AppRoutes.shop);
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
  // COMMUNITY HEADER
  // ===========================================================================

  Widget _buildCommunityHeader() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KsColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: KsColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.groups_rounded,
                  color: KsColors.terracotta,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'KalaSetu Samuh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: KsColors.ink,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Your artisan community',
                      style: TextStyle(
                        fontSize: 12,
                        color: KsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: KsColors.greenSoft,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 14,
                      color: KsColors.greenDark,
                    ),

                    SizedBox(width: 5),

                    Text(
                      '2.4K',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KsColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'Connect with artisans, discover craft stories, '
            'and grow together.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: KsColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildCommunityStat(
                value: '2.4K',
                label: 'Members',
              ),

              _buildStatDivider(),

              _buildCommunityStat(
                value: '186',
                label: 'Artisans',
              ),

              _buildStatDivider(),

              _buildCommunityStat(
                value: '42',
                label: 'New this week',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStat({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: KsColors.ink,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: KsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28,
      width: 1,
      color: KsColors.border,
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
    );
  }

  // ===========================================================================
  // FILTER BAR
  // ===========================================================================

  Widget _buildFilterBar() {
    return SizedBox(
      height: 38,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),

        itemCount: _filters.length,

        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },

        itemBuilder: (context, index) {
          final bool selected = _selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),

              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),

              decoration: BoxDecoration(
                color: selected
                    ? KsColors.terracotta
                    : KsColors.surface,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: selected
                      ? KsColors.terracotta
                      : KsColors.border,
                ),
              ),

              child: Text(
                _filters[index],

                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,

                  color: selected
                      ? KsColors.white
                      : KsColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // CREATE POST
  // ===========================================================================

  Widget _buildCreatePostCard() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: KsColors.border,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: const BoxDecoration(
              color: KsColors.terracottaSoft,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_outline_rounded,
              color: KsColors.terracotta,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Share something with your community...',
              style: TextStyle(
                fontSize: 13,
                color: KsColors.textMuted,
              ),
            ),
          ),

          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: KsColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.image_outlined,
              size: 20,
              color: KsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Community updates',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KsColors.ink,
            ),
          ),
        ),

        GestureDetector(
          onTap: () {},

          child: const Row(
            children: [
              Text(
                'Latest',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KsColors.terracotta,
                ),
              ),

              SizedBox(width: 3),

              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: KsColors.terracotta,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FEATURED NEWS / ANNOUNCEMENT
  // ===========================================================================

  Widget _buildFeaturedAnnouncement() {
    return Container(
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: KsColors.border,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // -------------------------------------------------------------------
          // IMAGE
          // -------------------------------------------------------------------

          Stack(
            children: [
              SizedBox(
                height: 205,
                width: double.infinity,

                child: Image.network(
                  _featuredImage,

                  fit: BoxFit.cover,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: KsColors.surfaceMuted,

                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: KsColors.textMuted,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // NEWS label
              Positioned(
                top: 14,
                left: 14,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: KsColors.terracotta,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: const Text(
                    'NEWS',
                    style: TextStyle(
                      color: KsColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ),

              // Bookmark
              Positioned(
                top: 12,
                right: 12,

                child: Container(
                  width: 34,
                  height: 34,

                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: KsColors.white,
                    size: 19,
                  ),
                ),
              ),

              // Image caption
              const Positioned(
                left: 16,
                right: 16,
                bottom: 15,

                child: Text(
                  'Craft, culture and opportunity come together',
                  style: TextStyle(
                    color: KsColors.white,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // ARTICLE DETAILS
          // -------------------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              15,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,

                      decoration: BoxDecoration(
                        color: KsColors.greenSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),

                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: KsColors.greenDark,
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: Text(
                        'KalaSetu Official',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: KsColors.ink,
                        ),
                      ),
                    ),

                    const Text(
                      '2h ago',
                      style: TextStyle(
                        fontSize: 10,
                        color: KsColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                const Text(
                  'IndiaHandmade integration is live',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: KsColors.ink,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Approved catalog cards can now be synced with '
                  'IndiaHandmade for greater visibility and easier '
                  'discovery by buyers.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.48,
                    color: KsColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    const Text(
                      'Learn more',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KsColors.greenDark,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: KsColors.greenDark,
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: KsColors.textSecondary,
                    ),

                    const SizedBox(width: 5),

                    const Text(
                      '28',
                      style: TextStyle(
                        fontSize: 10,
                        color: KsColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 16),

                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                      color: KsColors.textSecondary,
                    ),

                    const SizedBox(width: 5),

                    const Text(
                      '6',
                      style: TextStyle(
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
    );
  }

  // ===========================================================================
  // ARTISAN POST
  // ===========================================================================

  Widget _buildArtisanPost({
    required String author,
    required String location,
    required String time,
    required String initials,
    required Color avatarColor,
    required String imageUrl,
    required String content,
    required int likes,
    required int comments,
    required String category,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: KsColors.border,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // -------------------------------------------------------------------
          // AUTHOR HEADER
          // -------------------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              14,
              15,
              12,
            ),

            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,

                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),

                  alignment: Alignment.center,

                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: KsColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              author,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: KsColors.ink,
                              ),
                            ),
                          ),

                          const SizedBox(width: 5),

                          if (author == 'KalaSetu Artisan')
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: KsColors.green,
                            ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: KsColors.textMuted,
                          ),

                          const SizedBox(width: 2),

                          Flexible(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 10,
                                color: KsColors.textSecondary,
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                            ),

                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: KsColors.textMuted,
                              ),
                            ),
                          ),

                          Text(
                            time,

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

                const Icon(
                  Icons.more_horiz_rounded,
                  color: KsColors.textSecondary,
                  size: 21,
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // IMAGE
          // -------------------------------------------------------------------

          SizedBox(
            height: 205,
            width: double.infinity,

            child: Image.network(
              imageUrl,

              fit: BoxFit.cover,

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  color: KsColors.surfaceMuted,

                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: KsColors.textMuted,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),

          // -------------------------------------------------------------------
          // CONTENT
          // -------------------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              13,
              15,
              13,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: KsColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: Text(
                        category,

                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: KsColors.textSecondary,
                        ),
                      ),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: KsColors.textMuted,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      time,

                      style: const TextStyle(
                        fontSize: 9.5,
                        color: KsColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  content,

                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: KsColors.ink,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  height: 1,
                  color: KsColors.border,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildInteraction(
                      icon: Icons.favorite_border_rounded,
                      count: likes.toString(),
                    ),

                    const SizedBox(width: 22),

                    _buildInteraction(
                      icon: Icons.chat_bubble_outline_rounded,
                      count: comments.toString(),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 19,
                      color: KsColors.textSecondary,
                    ),

                    const SizedBox(width: 17),

                    const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: KsColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteraction({
    required IconData icon,
    required String count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(
          icon,
          size: 19,
          color: KsColors.textSecondary,
        ),

        const SizedBox(width: 6),

        Text(
          count,

          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: KsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}