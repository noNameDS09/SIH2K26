import 'package:flutter/material.dart';

class OutwardDistributionScreen extends StatelessWidget {
  const OutwardDistributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────
            // TOP BAR
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE3DED4),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      color: const Color(0xFF2E2A26),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outward Distribution',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF25211E),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Your product is ready to sell',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF817A72),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _TopLogo(),
                ],
              ),
            ),

            // ─────────────────────────────────────────────
            // STAGE INDICATOR
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _stageCircle('1', false),
                      _stageLine(),
                      _stageCircle('2', false),
                      _stageLine(),
                      _stageCircle('3', false),
                      _stageLine(),
                      _stageCircle('4', false),
                      _stageLine(),
                      _stageCircle('5', true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'STAGE 5  •  OUTWARD DISTRIBUTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF9A5B32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────
            // CONTENT
            // ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SUCCESS ICON
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EFE2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC9D9C1),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: Color(0xFF66815D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Center(
                      child: Text(
                        'Published & Ready to Sell.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF29241F),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Your verified product is now ready '
                            'for multi-channel distribution.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF746D65),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // PRODUCT SUMMARY CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE4DED5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PUBLISHED PRODUCT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF9A5B32),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECE5DA),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 30,
                                  color: Color(0xFFB7AA9A),
                                ),
                              ),

                              const SizedBox(width: 14),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Devi Ram Weavers',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2C2722),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Chandheri Cluster',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF756E66),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Pure Silk  •  ₹3,850',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF9A5B32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F7F0),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 19,
                                  color: Color(0xFF66815D),
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Verified and successfully published',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF53654D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DISTRIBUTION OPTIONS
                    const Text(
                      'DISTRIBUTION CHANNELS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF9A5B32),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _DistributionCard(
                      icon: Icons.chat_outlined,
                      title: 'Direct WhatsApp Pack',
                      subtitle:
                      'Generate a ready-to-share product catalogue card.',
                      buttonText: 'CREATE PACK',
                    ),

                    const SizedBox(height: 10),

                    _DistributionCard(
                      icon: Icons.storefront_outlined,
                      title: 'Marketplace Adapters',
                      subtitle:
                      'Prepare your verified listing for supported marketplaces.',
                      buttonText: 'VIEW ADAPTERS',
                    ),

                    const SizedBox(height: 10),

                    _DistributionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Cluster Field Verification',
                      subtitle:
                      'View verification status and artisan cluster proof.',
                      buttonText: 'VIEW PROOF',
                    ),

                    const SizedBox(height: 24),

                    // CREATE ANOTHER PRODUCT
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO:
                          // Navigate back to product creation.
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 21,
                        ),
                        label: const Text(
                          'CREATE ANOTHER PRODUCT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(0xFF9A5B32),
                          side: const BorderSide(
                            color: Color(0xFFD2B59C),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // BOTTOM NAVIGATION
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE6E0D7),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    active: false,
                  ),
                  _BottomNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    active: true,
                  ),
                  _BottomNavItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Insights',
                    active: false,
                  ),
                  _BottomNavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    active: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOP LOGO
// ─────────────────────────────────────────────────────────

class _TopLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF9A5B32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'KS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STAGE INDICATOR
// ─────────────────────────────────────────────────────────

Widget _stageCircle(String number, bool active) {
  return Container(
    width: 25,
    height: 25,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active
          ? const Color(0xFF9A5B32)
          : const Color(0xFFE5DED5),
    ),
    child: Center(
      child: Text(
        number,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: active
              ? Colors.white
              : const Color(0xFF847B72),
        ),
      ),
    ),
  );
}

Widget _stageLine() {
  return Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: const Color(0xFFE0D9D0),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// DISTRIBUTION CARD
// ─────────────────────────────────────────────────────────

class _DistributionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;

  const _DistributionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE4DED5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF4E9DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9A5B32),
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF302A25),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF817A72),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF9A5B32),
            size: 23,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BOTTOM NAV ITEM
// ─────────────────────────────────────────────────────────

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 21,
          color: active
              ? const Color(0xFF9A5B32)
              : const Color(0xFF8B837A),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
            active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? const Color(0xFF9A5B32)
                : const Color(0xFF8B837A),
          ),
        ),
      ],
    );
  }
}