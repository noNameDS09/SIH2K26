import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});
  @override Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Image.asset('assets/heroes/KS-Hero-2.png', fit: BoxFit.cover),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('My Catalog', style: KsTextStyles.section),
              backgroundColor: KsColors.surface.withOpacity(0.92),
              elevation: 0,
            ),
            body: Center(
              child: Text('Catalog from /v1/listings. Real data via adapter.', style: KsTextStyles.body()),
            ),
          ),
        ],
      );
}
