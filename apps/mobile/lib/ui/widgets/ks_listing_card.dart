import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

/// One listing row: photo, bilingual title, status badge, listed price.
/// Used on `/shop`, `/home` (recent), and referenced by `/approval`,
/// `/distribute`.
class KsListingCard extends StatelessWidget {
  const KsListingCard({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPublished = listing.status == ListingStatus.published;
    final photoUrl = listing.studioUrl ?? listing.originalUrl;
    final title = listing.titleEn ?? listing.titleHi ?? 'Untitled draft';
    final price = listing.prices.listed ?? listing.prices.recommended?.value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KsColors.surface1,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56,
                height: 56,
                color: KsColors.surfaceMuted,
                child: photoUrl != null
                    ? Image.network(photoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_outlined, color: KsColors.textSecondary))
                    : const Icon(Icons.image_outlined, color: KsColors.textSecondary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KsTextStyles.bodyMedium(size: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    price != null ? '₹$price' : 'No price yet',
                    style: KsTextStyles.price(color: KsColors.terracotta, size: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPublished ? KsColors.paleGreen : KsColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPublished ? 'Published' : 'Draft',
                style: KsTextStyles.label(
                    color: isPublished ? KsColors.deepGreen : KsColors.textSecondary, size: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
