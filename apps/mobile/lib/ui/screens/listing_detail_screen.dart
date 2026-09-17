import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_cards.dart';
import '../../services/api_service.dart';

/// Native equivalent of the web's /v/[listingId] PublicListingView.
class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _listing;
  bool _loading = true;
  String? _error;
  late TabController _tabCtrl;

  static const _tabs = ['Details', 'Story', 'Care', 'Verification'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final data = await ApiService.getPublicListing(widget.listingId);
    if (!mounted) return;
    setState(() {
      _listing = data;
      _loading = false;
      if (data == null) _error = 'This craft record is not available.';
    });
  }

  String _field(String key, [String altKey = '']) {
    final fields = _listing?['fields'] as Map<String, dynamic>? ?? {};
    final v = fields[key] ?? (altKey.isNotEmpty ? fields[altKey] : null);
    if (v == null) return '';
    return v.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(title: 'Product Card', onBack: () => context.pop()),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: KsColors.terracotta),
      );
    }
    if (_error != null || _listing == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: KsColors.textMuted),
              const SizedBox(height: 16),
              Text('Listing not available', style: KsTextStyles.section),
              const SizedBox(height: 8),
              Text(
                _error ?? 'It may still be a draft, or the link may have changed.',
                textAlign: TextAlign.center,
                style: KsTextStyles.body(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.shop),
                style: FilledButton.styleFrom(backgroundColor: KsColors.terracotta),
                child: const Text('Return to catalog'),
              ),
            ],
          ),
        ),
      );
    }

    final l = _listing!;
    final title = l['title_en'] ?? l['title'] ?? l['title_hi'] ?? 'Untitled craft';
    final craft = l['craft'] ?? l['category'] ?? 'Handmade craft';
    final artisanName = (l['artisan'] as Map?)?.containsKey('name') == true
        ? l['artisan']['name']
        : 'The artisan';
    final region = l['cluster_name'] ?? l['cluster'] ?? '';
    final price = l['listed_price'];
    final priceStr = price != null ? '₹${price.toString()}' : 'Price on request';
    final imageUrl = l['image_url'] ?? l['photo_url'];
    final signed = l['signature'] != null && (l['signature'] as String).isNotEmpty;

    final description = l['desc_en'] ?? l['description'] ?? l['desc_hi'] ?? '';
    final material = _field('material', 'materials');
    final technique = _field('technique', 'making_process');
    final dimensions = _field('dimensions', 'size');
    final care = _field('care', 'care_instructions');
    final story = _field('story', 'what_makes_it_special');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 240,
              width: double.infinity,
              color: KsColors.surfaceMuted,
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: KsColors.textMuted),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined, size: 48, color: KsColors.textMuted),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Provided by the artisan', style: KsTextStyles.caption),
          const SizedBox(height: 16),

          // Heading
          Text(craft, style: KsTextStyles.caption.copyWith(color: KsColors.terracotta, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: KsTextStyles.editorial(size: 22)),
          const SizedBox(height: 4),
          Text('By $artisanName${region.isNotEmpty ? ' · $region' : ''}', style: KsTextStyles.body()),
          const SizedBox(height: 8),
          Text(priceStr, style: KsTextStyles.price(color: KsColors.terracotta)),
          const SizedBox(height: 20),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: KsColors.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: KsColors.terracotta,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: KsColors.textSecondary,
              labelStyle: KsTextStyles.bodyMedium(size: 11),
              unselectedLabelStyle: KsTextStyles.body(size: 11),
              dividerHeight: 0,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tab content (static, controlled by listener)
          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (context, _) {
              switch (_tabCtrl.index) {
                case 0:
                  return _detailsPanel(material, technique, dimensions, region, care);
                case 1:
                  return _storyPanel(story.isNotEmpty ? story : description, l['desc_hi'] as String?);
                case 2:
                  return _carePanel(care);
                case 3:
                  return _verificationPanel(signed, l['signature'] as String?, l['signed_at'] as String?);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
          const SizedBox(height: 24),

          // Trust footer
          KsCard(
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 28,
                    color: signed ? KsColors.green : KsColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signed ? 'This listing is signed' : 'Signature not available',
                          style: KsTextStyles.bodyMedium()),
                      const SizedBox(height: 2),
                      Text(
                        signed
                            ? 'The artisan reviewed this product record before it became public.'
                            : 'Check back after the artisan completes approval.',
                        style: KsTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: KsColors.terracotta),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KsTextStyles.label()),
                const SizedBox(height: 2),
                Text(value, style: KsTextStyles.body(color: KsColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsPanel(String material, String technique, String dimensions, String region, String care) {
    final hasAny = material.isNotEmpty || technique.isNotEmpty || dimensions.isNotEmpty || region.isNotEmpty || care.isNotEmpty;
    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No product details have been added yet.', style: KsTextStyles.body()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(Icons.category_outlined, 'Material', material),
        _detailRow(Icons.build_outlined, 'Technique', technique),
        _detailRow(Icons.straighten_outlined, 'Dimensions', dimensions),
        _detailRow(Icons.place_outlined, 'Region', region),
        _detailRow(Icons.shield_outlined, 'Care', care),
      ],
    );
  }

  Widget _storyPanel(String story, String? descHi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.isNotEmpty ? story : 'No artisan story has been added to this listing yet.',
          style: KsTextStyles.body(color: KsColors.ink, size: 13),
        ),
        if (descHi != null && descHi.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KsColors.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: KsColors.terracotta, width: 3)),
            ),
            child: Text(descHi, style: KsTextStyles.body(color: KsColors.ink)),
          ),
        ],
      ],
    );
  }

  Widget _carePanel(String care) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Care for this piece', style: KsTextStyles.section),
        const SizedBox(height: 8),
        Text(
          care.isNotEmpty
              ? care
              : 'No specific care instructions were provided. Keep the piece clean, dry, and protected from harsh handling.',
          style: KsTextStyles.body(color: KsColors.ink, size: 13),
        ),
      ],
    );
  }

  Widget _verificationPanel(bool signed, String? signature, String? signedAt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 34,
                color: signed ? KsColors.green : KsColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(signed ? 'Signed by KalaSetu' : 'Verification pending',
                      style: KsTextStyles.section),
                  const SizedBox(height: 4),
                  Text(
                    signed
                        ? 'This record was approved by the artisan${signedAt != null ? ' on $signedAt' : ''}.'
                        : 'This public record has not yet been signed.',
                    style: KsTextStyles.body(),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (signed && signature != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: KsColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              signature.length > 28 ? '${signature.substring(0, 28)}…' : signature,
              style: KsTextStyles.caption.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }
}
